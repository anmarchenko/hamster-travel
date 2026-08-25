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

Phoenix keeps WebSocket origin checking enabled. For local validation the
canonical URL is `http://127.0.0.1:4400`. When enabling Tailscale Serve, set
`PHX_HOST` to the full MagicDNS hostname, `PHX_SCHEME=https`, `PHX_PORT=443`,
and `PHX_CHECK_ORIGINS=https://<full-magicdns-hostname>` before redeploying.
`PHX_CHECK_ORIGINS` accepts a comma-separated list of explicit origins; wildcard
origins are rejected.

The deployment wrapper starts an ephemeral registry on `127.0.0.1:5555` and
removes it after each local deployment. It has no persistent volume. Set
`KAMAL_REGISTRY_SERVER=ghcr.io` and configure `KAMAL_REGISTRY_PASSWORD` when
moving image storage to GHCR.

Production keeps Chromium warm for fast PDF generation. The container uses a
writable tmpfs home and `/dev/shm`, four reusable ChromicPDF sessions, two
Ghostscript workers, an 8-CPU limit, and a 6 GiB memory limit. These defaults
can be adjusted with `CHROMIC_PDF_POOL_SIZE` and
`CHROMIC_PDF_GHOSTSCRIPT_POOL_SIZE` without rebuilding the image. Application
startup performs a real PDF render before the release is considered healthy,
so the first user request does not pay Chromium's initialization cost.

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

## Backups

Production backups are PostgreSQL custom-format archives with no application
encryption layer. They are kept locally in
`~/Work/hamster-travel-production/backups` with directory mode `0700` and file
mode `0600`, then uploaded to the same S3 bucket used by the retired GitHub
Actions backup, under the new `beelink-db-backups/` prefix. S3 may still apply
its own transparent storage encryption; a downloaded archive does not require
a separate decryption key.

The uploader reads defaults from `.envrc` and lets values in
`~/Work/hamster-travel-production/.env` override them. To keep database-backup
access separate from the application's image-upload identity, set
`HAMSTER_TRAVEL_BACKUP_AWS_ACCESS_KEY_ID`,
`HAMSTER_TRAVEL_BACKUP_AWS_SECRET_ACCESS_KEY`,
`HAMSTER_TRAVEL_BACKUP_AWS_REGION`, and
`HAMSTER_TRAVEL_BACKUP_AWS_S3_BUCKET` in that production environment file.
Neither environment file is committed. Run and validate a backup manually
with:

```bash
scripts/backup-production
scripts/restore-test-production-backup
```

Install the checked-in user service and timer under `~/.config/systemd/user/`.
The backup timer runs every six hours at approximately 00:15, 06:15, 12:15,
and 18:15, with up to ten minutes of randomized delay, matching the retired
workflow cadence. A backup is successful only after both the dump and its
checksum are uploaded and their remote sizes are verified. Only then does the
backup script update `.last-successful-backup` in the backup directory.

Install and enable the checked-in backup watchdog service and timer as well.
It checks the success marker hourly and sends one critical desktop notification
when no verified backup has completed for more than 24 hours. It does not send
the notification again during the same outage; a later successful backup
automatically arms the notification for the next outage.

## Tailscale

Tailscale comes only after local functional, restart, rollback, persistence, and
network-isolation checks pass. PostgreSQL remains loopback-only; Tailscale Serve
will expose only the application endpoint. Run `mix hex.audit` immediately
before exposure and review every remaining advisory rather than accepting it
implicitly.
