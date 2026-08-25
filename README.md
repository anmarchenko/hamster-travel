# Hamster Travel

This is a second take on my personal travel planner that we as a family use since 2014. This version is a full rewrite of the project and is under active development. You can read a bit more about planned features on my [personal website](https://www.amarchenko.de/hamster-travel/).

The old version is still in use and available on [https://travel.hmstr.rocks](https://travel.hmstr.rocks/en/landing) (source code for the old Hamster Travel is also on [github](https://github.com/anmarchenko/hamster_travel_legacy)).

## Prerequisites

- [elixir](https://elixir-lang.org)
- [postgres](https://www.postgresql.org)

## Run locally

Run the following commands to setup dependencies and create the database:

```bash
mix deps.get
mix ecto.setup
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

Production is deployed with Kamal. See [docs/production-deployment.md](docs/production-deployment.md).
