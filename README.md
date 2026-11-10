# ScreenHive — Production DevOps Deployment

Infrastructure and delivery automation for [ScreenHive](https://github.com/Ritacloud23/Cinema_Booking_API), a FastAPI cinema-booking API.

> **Project status:** Initial setup. AWS infrastructure has not yet been provisioned and no live deployment is claimed.

## Goals

Demonstrate a repeatable, infrastructure-as-code deployment of the existing application to AWS, with containerization, automated build/test/deploy, and operational logging.

## Planned architecture

- **Application:** Existing ScreenHive FastAPI service (source remains in the application repository).
- **Compute:** Amazon EC2 running Docker Compose.
- **Registry:** Amazon Elastic Container Registry (ECR).
- **Infrastructure as Code:** Terraform, organized into reusable modules.
- **CI/CD:** GitHub Actions — test, build, publish, and deploy.
- **Deployment transport:** AWS Systems Manager (SSM) Run Command; no public SSH ingress required.
- **Observability:** CloudWatch Logs and EC2/system metrics.
- **Region:** `us-east-1`.

EC2 is selected as the lower-complexity, cost-conscious option permitted by the challenge. This is a single-instance assessment environment, not a highly available production architecture.

## Architecture diagram

See [docs/architecture.mmd](docs/architecture.mmd).

## Repository layout

```text
.
├── .github/workflows/       # CI/CD workflows
├── docs/                    # Architecture and operational notes
├── terraform/
│   ├── environments/dev/    # Environment composition
│   └── modules/             # Reusable infrastructure modules
├── scripts/                 # Deployment and operational scripts
├── .gitignore
└── README.md
```

## Delivery workflow

The intended pipeline will:

1. Check out this infrastructure repository and the ScreenHive application repository.
2. Install application dependencies and run the existing automated tests.
3. Build the application Docker image and tag it with the commit SHA.
4. Authenticate to AWS using GitHub OIDC (no long-lived AWS access keys in GitHub).
5. Push the image to ECR.
6. Trigger an SSM deployment on the EC2 instance.
7. Verify the deployed service health endpoint.

The workflow will be enabled only after its AWS role, repository trust policy, ECR repository, and instance configuration are in place.

## Application configuration

The application depends on external services and configuration. Before deployment, we will inspect the application settings and define the required environment variables explicitly. Credentials must be supplied through secure runtime configuration and must never be committed to Git.

Database and Redis deployment choices, Firestore configuration, payment integration settings, and migration behavior must be validated against the application code before the first production deployment.

## Infrastructure deployment

Terraform configuration and commands will be documented here after the modules are implemented. Terraform state must not be committed to this repository. For this time-boxed assessment, the initial setup may use a local state file on the operator's machine; a remote, locked state backend is a recommended improvement for team use.

## Cost and security considerations

- Use a small, region-appropriate EC2 instance after checking account eligibility and current AWS pricing.
- Avoid NAT gateways and managed load balancers in the initial low-budget design.
- Restrict inbound application access to the required port(s); do not expose PostgreSQL or Redis publicly.
- Prefer SSM Session Manager/Run Command over inbound SSH.
- Use an EC2 instance profile for ECR pulls and CloudWatch/SSM permissions.
- Use GitHub OIDC with least-privilege IAM permissions.
- Configure log retention and clean up unused resources after the assessment.
- AWS charges may apply even to small instances, storage, public IPv4 addresses, and data transfer. Check the AWS Pricing Calculator and billing dashboard before provisioning.

## Known limitations and planned improvements

- A single EC2 instance is a single point of failure and has limited horizontal scalability.
- The initial environment is intended for an assessment, not regulated or high-availability workloads.
- A managed database, multi-AZ architecture, TLS/domain setup, centralized secret management, vulnerability scanning, and automated rollback are potential follow-up improvements.
- Actual deployment status, endpoint, test results, and screenshots will be added only after they have been verified.

## Assessment checklist

- [ ] Terraform provisions AWS infrastructure.
- [ ] Application image builds successfully.
- [ ] Automated tests pass in CI.
- [ ] Image is published to ECR.
- [ ] Deployment is triggered automatically through SSM.
- [ ] Public health endpoint responds successfully.
- [ ] CloudWatch receives application logs and instance metrics.
- [ ] README includes verified deployment evidence and cleanup instructions.

## Related repository

Application source: https://github.com/Ritacloud23/Cinema_Booking_API
