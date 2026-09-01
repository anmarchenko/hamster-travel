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
