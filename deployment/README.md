# Hamster Travel deployment tool

This directory is a self-contained Go module for local production deployment.
It intentionally keeps deployment code and infrastructure templates separate
from the Phoenix/Elixir application tree.

Contents:

- `cmd/hamster-deploy`: CLI entry point;
- `internal/deploy`: deployment transaction and tests;
- `compose.yaml`: production Docker Compose definition;
- `app.env.example` and `database.env.example`: scoped secret templates.

The normal build, test, and installation command from the repository root is:

```bash
mix deploy.build
```

The direct Go commands are:

```bash
go test ./...
go vet ./...
go build -trimpath -o /tmp/hamster-deploy ./cmd/hamster-deploy
sudo install --owner=root --group=root --mode=0755 \
  /tmp/hamster-deploy /usr/local/sbin/hamster-deploy
```

The full installation, routine operation, rollback, and recovery instructions
are stored with the machine-local production infrastructure rather than in this
public repository.

On the production host, the deployer resolves the default app and database
inputs from the installed fnox manifest into temporary files under `/run`.
Use `sudo /usr/local/sbin/hamster-deploy check-config` to validate those inputs
without changing containers or displaying resolved values.

## Weekly base image updates

The weekly ChatGPT automation runs from a clean worktree based on
`origin/master`. The script checks stable Elixir and Erlang/OTP releases and
dated slim images for the Debian codename pinned in the Dockerfile. It verifies
the published Linux amd64 builder, runner, and Node tags. A new Debian codename
is a separate Dockerfile change.

Run these from the repository root to update and then verify the pins.

```bash
python3 scripts/update-production-images
python3 scripts/update-production-images --check
git diff --check
```

The automation commits and pushes verified Dockerfile changes. Deployment is
a separate operation.
