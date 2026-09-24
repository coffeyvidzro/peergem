# PeerGem

PeerGem is a Rails application running on Ruby 4.0.7 and PostgreSQL. Its UI is
server-rendered ERB enhanced with Turbo, Stimulus, Tailwind CSS, Propshaft, and
importmap—no Node.js runtime is required.

## Services

- **PostgreSQL** stores application data.
- **Redis** backs the Rails cache, Sidekiq, Redlock, and Stoplight circuit state.
- **Sidekiq** runs Active Job workloads and scheduled jobs.
- **Cloudflare R2** stores production Active Storage objects; development uses
  an S3-compatible MinIO endpoint and tests use temporary disk storage.
- **AWS SES v2** delivers production email.
- **MaxMind GeoIP2** is enabled when a database exists at
  `GEOIP_DATABASE_PATH`.
- **Lograge** emits JSON request logs and **Sentry** captures application and
  Sidekiq errors in production/staging.
- **OkComputer** exposes authenticated dependency checks at `/health` in
  production/staging. `/up` remains the unauthenticated process liveness probe.
- **AvaTax**, **Faraday**, **Stoplight**, **AASM**, and **Redlock** support domain
  integrations and workflows.

## Local setup

1. Install Ruby 4.0.7, PostgreSQL, and Redis.
2. Copy `.env.example` to `.env` (or export the values through your preferred
   environment manager).
3. Create the PostgreSQL role declared by `DATABASE_USERNAME`, then run:

   ```sh
   bin/setup
   bin/dev
   ```

The Rails server listens at <http://localhost:3000>. `bin/dev` also starts the
Tailwind watcher. Run a worker separately with `bin/sidekiq -C config/sidekiq.yml`.

## Verification

```sh
bin/rspec
bin/rubocop
bin/brakeman --no-pager
bin/importmap audit
```

Production additionally requires `APP_HOST`, database credentials (preferably
`DATABASE_URL`), R2 credentials, SES-compatible AWS credentials, and health
check credentials. See `.env.example` for the complete contract.
