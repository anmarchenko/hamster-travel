# Production deployment

Production is deliberately separate from the development PostgreSQL container,
volume, network, and port `6000`. Do not use the development Compose project for
production operations.

## Layout

- Application deployment: this repository, via Kamal destination `production`.
- PostgreSQL and network: `~/Work/hamster-travel-production/compose.yaml`.
- Application endpoint on the host: `http://127.0.0.1:4400`.
- PostgreSQL endpoint on the host: `127.0.0.1:65432`.
- Container network: external Docker network `kamal`.

The application runs without `kamal-proxy` during the local-validation stage.
This avoids an additional persistent proxy volume, but deployments have a short
interruption while the old container releases port `4400`.

The deployment wrapper starts an ephemeral registry on `127.0.0.1:5555` and
removes it after each local deployment. It has no persistent volume. Set
`KAMAL_REGISTRY_SERVER=ghcr.io` and configure `KAMAL_REGISTRY_PASSWORD` when
moving image storage to GHCR.

The wrapper builds the next image while the current release is still serving,
stops the old container only for the loopback port handoff, and restarts it if
the new container cannot be deployed. After the new release is healthy, the
wrapper runs migrations and the disposable Waffle storage check.

For local dirty-tree deployments, the wrapper generates one timestamped Kamal
version and uses it for both build and deploy. Set `KAMAL_VERSION` explicitly
when a stable external version identifier is required.

## Secrets

Copy `.kamal/secrets.example` to `.kamal/secrets.production`. Keep the file mode
at `0600` and source every value from the environment or a password manager.
Literal secret values must not be committed.

The AWS key must be authorized for the production bucket. At minimum, Waffle
needs permission to upload and delete objects in that bucket, and the generated
asset URLs must be publicly readable. Do not substitute the development bucket
or its credentials to make a production check pass.

## Deploy

Start and validate production PostgreSQL from its Compose directory first, then:

```bash
scripts/deploy-production
curl --fail --silent --show-error http://127.0.0.1:4400/up
```

The deployment is not successful unless the final Waffle check reports:

```text
Waffle production storage check passed: upload, public fetch, delete, cleanup
```

Run the same disposable check independently with:

```bash
kamal verify-storage --destination production
```

Run migrations independently when restoring a database or when diagnosing a
deployment:

```bash
kamal migrate --destination production
```

## Database dump

Do not mount database dumps into a container. After validating the dump format,
version, and checksum, use a `pg_restore` client at least as new as the client
that created the archive. Restore through the loopback-only PostgreSQL port with
`--single-transaction --no-owner --no-acl`, run the release migrations, verify
important table counts and constraints, and create a post-restore backup.

## Tailscale

Tailscale comes only after local functional, restart, rollback, persistence, and
network-isolation checks pass. PostgreSQL remains loopback-only; Tailscale Serve
will expose only the application endpoint. Run `mix hex.audit` immediately
before exposure and review every remaining advisory rather than accepting it
implicitly.
