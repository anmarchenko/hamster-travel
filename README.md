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
