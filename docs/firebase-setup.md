# Firebase and Firestore setup

ScreenHive's live showtime board and Server-Sent Events stream use Firestore. This deployment keeps Firestore enabled.

## Before deployment

Have these values ready:
- Firebase project ID
- Service-account JSON downloaded from the Firebase project
- Firestore enabled in that project
- A service account with the minimum Firestore access needed by the application

**Never commit the JSON file, paste it into chat, add it to a GitHub variable, or put it in Terraform code/state.**

## Create encrypted parameters

After Terraform creates the EC2 instance and its IAM role, open AWS Systems Manager → Parameter Store in us-east-1.

Create the following parameters using type SecureString.

### /screenhive/dev/runtime-env

Use a multiline environment-file value similar to this:

    POSTGRES_USER=screenhive
    POSTGRES_PASSWORD=GENERATE_A_LONG_UNIQUE_PASSWORD
    POSTGRES_DB=screenhive
    JWT_SECRET=GENERATE_A_DIFFERENT_LONG_RANDOM_SECRET
    PAYSTACK_SECRET=YOUR_PAYSTACK_SECRET_IF_PAYMENTS_ARE_ENABLED
    FIREBASE_PROJECT_ID=YOUR_FIREBASE_PROJECT_ID

Replace every example value. Do not use the development passwords from the original local Compose file.

### /screenhive/dev/firebase-service-account

Set the value to the complete JSON content of the Firebase service-account file. Do not include Markdown fences or surrounding quotes.

Standard Parameter Store SecureString values have a 4 KB size limit. Check the JSON file size before creating the parameter. If it exceeds the limit, stop and choose a suitable secrets-storage design rather than splitting or truncating the JSON.

## Runtime behavior

At deployment time, the EC2 instance role retrieves both parameters with decryption. The host writes them to files with restrictive permissions. Docker Compose mounts the service-account JSON read-only at /run/secrets/firebase-service-account.json and sets FIRESTORE_ENABLED=true, FIREBASE_CREDENTIALS_PATH=/run/secrets/firebase-service-account.json, and FIREBASE_PROJECT_ID from the runtime environment file.

The API uses the Firebase Admin SDK to initialize Firestore.

## Validation

After deployment:
1. Check the API container logs in CloudWatch for Firebase initialization or permission errors.
2. Test GET / for basic API health.
3. Test the live showtime stream using a real showtime ID. A successful root endpoint does not prove Firestore connectivity.
