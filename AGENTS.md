# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview
- Phoenix LiveView app for family travel planning.
- Context-driven design with domain boundaries for accounts, planning, packing, geo, social.
- Frontend uses Tailwind CSS, Alpine.js, Petal Components, Heroicons, and Live Select.
- Internationalization via gettext (English and Russian).

## Commands

### Setup
```bash
# Full project setup (deps, DB, assets)
mix setup

# Basic setup
mix deps.get
mix ecto.setup
```

### Development Server
```bash
# Start Phoenix server (http://localhost:4000)
mix phx.server

# Test credentials: bunny@hamsters.test / test1234
```

### Formatting
```bash
# Format all files
mix format

# Check formatting only
mix format --check-formatted
```

### Testing
```bash
# Run all tests
mix test

# Run a single test file
mix test test/hamster_travel/accounts_test.exs

# Run a single test by line number
mix test test/hamster_travel/accounts_test.exs:123

# Run with coverage
mix test --cover
```

### Lint
```bash
# Lint code (strict)
mix credo --strict
```

### Assets
```bash
# Build assets for development
mix assets.build

# Build assets for production
mix assets.deploy
```

### Database
```bash
# Run migrations
mix ecto.migrate

# Roll back last migration
mix ecto.rollback

# Reset DB (drop, create, migrate, seed)
mix ecto.reset

# psql alias
psqlhtl
psqlhtl -c "SELECT * FROM users;"
```

### Internationalization
```bash
# Extract and merge translations
mix gettext
```

### After Code Changes
- Run `mix format`, `mix test`, and `mix credo --strict` after code changes.

## Architecture and Structure
- Context APIs live in `lib/hamster_travel/*.ex`, internal modules in `lib/hamster_travel/<context>/`.
- LiveViews and components live in `lib/hamster_travel_web/live/`.
- LiveComponents for stateful UI; function components in `*_components.ex`.
- Keep controllers thin and delegate business logic to contexts.
- Use `Req` for HTTP clients; define behaviours for API clients to enable mocking.

## Code Style Guidelines

### Formatting and Layout
- Use `mix format` for all changes; formatter inputs include `*.{ex,exs,heex}`.
- HEEx formatting uses `Phoenix.LiveView.HTMLFormatter`.
- Keep lines within 120 characters (Credo max line length).

### Module Organization
- Order sections: `defmodule`, `@moduledoc` (optional), `use`, `require`, `import`, `alias`.
- Group aliases by namespace with `{}` and keep them alphabetical within the block.
- Use `@impl true` for LiveView/LiveComponent callbacks.

### Imports and Aliases
- Prefer `alias` over `import` for regular modules.
- Use `import` only for macros/helpers that are used heavily (e.g., `Ecto.Query`).
- Use fully-qualified names when it improves clarity.

### Naming
- Modules are `HamsterTravel.*` or `HamsterTravelWeb.*` with PascalCase.
- File names and function names are `snake_case`.
- Predicate functions end in `?` and raising variants end in `!`.
- Component modules use clear suffixes: `FooForm`, `FooNew`, `Foo`.
- Event names in `handle_event/3` are snake_case strings.

### Types and Specs
- Add `@spec` for public context APIs or non-trivial functions.
- Define struct types (`@type t`) when referenced across contexts or in specs.

### Changesets and Data Access
- Use `Ecto.Changeset` pipelines with validations near the schema.
- Return `{:ok, struct}` or `{:error, %Ecto.Changeset{}}` for CRUD operations.
- Use `get!/1` only when callers expect a raise; otherwise return `nil` or error tuples.
- Use `Ecto.Multi` for multi-step writes when consistency matters.

### Error Handling
- Use `{:error, reason}` or tagged tuples for domain errors.
- Use `with` for sequential operations; avoid `rescue` unless necessary.
- Handle external HTTP failures and timeouts explicitly.

### LiveView and Components
- Use `attr` declarations for LiveComponent assigns.
- Use `to_form/1` for changesets in components.
- Process special inputs (like live select values) before submission.
- Use `gettext/1` for all user-facing strings.

### Testing
- Use `HamsterTravel.DataCase` or `HamsterTravelWeb.ConnCase`.
- Prefer fixtures from `test/support/fixtures/`.
- Follow Arrange/Act/Assert and use `async: true` when no DB access is needed.

## Project Rules
- Check if port 4000 is already in use before running `mix phx.server`.
- Never commit changes; the user will review before committing.

## Editor Rules
- No Cursor rules found in `.cursor/rules/` or `.cursorrules`.
- No Copilot instructions found in `.github/copilot-instructions.md`.
