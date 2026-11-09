# Hamster Travel

My personal travel planner,

## Run locally

Run the following commands to setup dependencies and create the database:

```bash
mix deps.get
mix setup
```

Run server:

```bash
mix phx.server
```

Visit `http://localhost:4000` to start using the app.
Use credentials from `priv/repo/seeds.exs`, for example `bunny@hamsters.test` with password `test1234`.

### Refresh dev travel data from production

On the machine running both PostgreSQL containers, use a migrated dev database
with the seeded Bunny account. Preview the source counts, then apply the refresh.

```bash
sudo ./scripts/refresh-dev-travel --dry-run
sudo ./scripts/refresh-dev-travel --replace
```

The refresh removes all dev trips, deleted-trip history, and backpacks across all
users. It gives Bunny ownership of the production trips Andrey Marchenko can open
(including public trips) and of the backpacks owned by Andrey or his friends.
Imported trips start with empty participant lists. The refresh skips trip covers
and strips embedded images from rich text. Dev accounts and logins are preserved.
The dev replacement runs in one transaction.

When adding, removing, or editing a migration, review
`scripts/sql/export-dev-travel.sql` and `scripts/sql/replace-dev-travel.sql`.
Update the SQL for changes to travel data, relationships, or reference tables.
Once reviewed, format the migrations, regenerate the schema lock, and include it
in the same PR.

```bash
./scripts/refresh-dev-travel --print-schema-lock > scripts/sql/dev-travel-schema.lock
./scripts/refresh-dev-travel --check-schema
```

The pre-commit hook and CI check the migration file checksums against the lock.
Before proceeding, the refresh compares the applied migration versions on both
databases. Make changes to an already-deployed schema in a new migration so the
refresh can detect them.

## Pre-commit checks

Enable the repository's hook once per checkout.

```bash
git config --local core.hooksPath .githooks
```

The hook runs `mix format` and stages the formatting changes. It then runs the
same checks as CI for the migration lock, compilation, strict Credo, and both Mix
test suites. Set up Mix dependencies, local PostgreSQL on port 6000, and the
[Chromium test prerequisites](test/e2e/README.md) before using it.

Stage or set aside unstaged changes and untracked files before committing so the
hook checks the files being committed. Run `./scripts/check` to check your working
tree at any time.

## Run tests

```bash
mix test
```

## Lint

```bash
mix credo --strict
```

## Deployment

Production is deployed locally with Docker Compose and the Go deployment tool.
Production runbooks are stored with the machine-local infrastructure rather than
in this public repository.

Common production operations are available through Mix:

```bash
mix deploy.status
mix deploy.run
mix db.prod.backup
```

## JavaScript dependencies

Install the locked npm dependency tree or update dependencies allowed by
`assets/package.json`:

```bash
mix assets.npm.install
mix assets.npm.update
```

`mix assets.build` and `mix assets.deploy` run `mix assets.npm.install`
automatically before compiling assets.
