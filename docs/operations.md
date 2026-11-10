# Operational notes

## Verified application facts

- FastAPI entry point: `app.main:app`.
- The existing Dockerfile uses Python 3.14 slim and installs dependencies with `uv sync --frozen --no-dev`.
- Runtime dependencies include PostgreSQL (psycopg), Redis, SQLModel, Alembic, and APScheduler.
- Existing local Compose uses PostgreSQL 16 and Redis 7.
- The application reads `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `PAYSTACK_SECRET`, and Firebase/Firestore settings from environment variables.
- The existing local Compose explicitly sets `FIRESTORE_ENABLED=false`; the application settings default this flag to true. This deployment example defaults it to false, but only keep it disabled if the deployed features do not require Firestore.
- The app starts an APScheduler job during FastAPI lifespan startup. Run a single API replica unless the scheduler is made distributed/leader-elected, otherwise multiple replicas may run duplicate jobs.
- Alembic migration command: `./.venv/bin/alembic upgrade head`.

## Production configuration

1. Copy `.env.example` to `.env` on the EC2 host and replace every placeholder.
2. Set `ECR_IMAGE` to the immutable image tag published by the pipeline.
3. Keep the database and Redis services on the private Docker network; do not publish their ports.
4. The API container runs database migrations before starting Uvicorn.
5. Create the CloudWatch log group with Terraform before starting Compose. The Docker awslogs driver is configured not to create it automatically.
6. Back up the PostgreSQL volume before destructive changes.

## Important security follow-ups

The original development Compose file contains hard-coded sample passwords and secrets and publishes PostgreSQL/Redis ports. Do not reuse those values in AWS. Generate unique secrets, keep the runtime `.env` out of Git, and review the application's SQL logging and container user before treating this as production-ready.

## Scheduler limitation

The API starts an APScheduler process on application startup. Keep one API container/replica for this architecture. A future multi-instance deployment should move scheduled work to a dedicated worker or use a distributed scheduler/lock.
