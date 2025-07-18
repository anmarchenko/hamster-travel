# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Setup
```bash
# Full project setup (dependencies, database, assets)
mix setup

# Basic setup for development
mix deps.get
mix ecto.setup
```

### Development Server
```bash
# Start Phoenix server (runs on http://localhost:4000)
mix phx.server

# Test credentials: bunny@hamsters.test / test1234
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/hamster_travel/accounts_test.exs

# Run with coverage
mix test --cover
```

### Code Quality
```bash
# Lint code with strict rules
mix credo --strict
```

### Ecto database schema
```bash
# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback
```

### Query the database

```bash
# psql alias to connect to local database
psqlhtl

# execute a query
psqlhtl -c "SELECT * FROM users;"
```

### Assets
```bash
# Build assets for development
mix assets.build

# Deploy assets for production
mix assets.deploy
```

### Internationalization
```bash
# Extract and update translations
mix gettext
```

## Architecture

### Phoenix LiveView Application
This is a **Phoenix LiveView** application - server-side rendered with real-time updates. The frontend uses **Tailwind CSS** and **Alpine.js** for styling and client-side interactions.

### Context-Driven Design
The application follows Phoenix's context pattern with clear domain boundaries:

- **Accounts** (`lib/hamster_travel/accounts.ex`) - User management and authentication
- **Planning** (`lib/hamster_travel/planning.ex`) - Trip planning with destinations, accommodations, transfers, expenses
- **Packing** (`lib/hamster_travel/packing.ex`) - Backpack management with lists and items
- **Geo** (`lib/hamster_travel/geo.ex`) - Geographic data (countries, regions, cities)
- **Social** (`lib/hamster_travel/social.ex`) - Friend relationships

### File Organization Patterns

#### Context Structure
Each context follows this pattern:
```
lib/hamster_travel/
  accounts/           # Domain modules
  accounts.ex         # Public context API
```

#### LiveView Organization
LiveViews are organized by domain with components co-located:
```
lib/hamster_travel_web/live/
  planning_live/
    show_trip.ex
    create_trip.ex
    components/
      destination_form.ex
      trip_form.ex
      planning_components.ex
```

### Component Patterns
- **LiveComponents**: Use for stateful, reusable UI components (e.g., form components)
- **Function Components**: Use for simple, stateless UI elements in `*_components.ex` files
- **Component Collections**: Group related function components in files like `planning_components.ex`

## Development Best Practices

### Phoenix/LiveView Patterns
- **LiveView-First**: Use LiveView as the primary UI technology
- **Function Components**: Use function components for reusable UI elements
- **Context Boundaries**: Respect context boundaries in controllers and LiveViews
- **Thin Controllers**: Keep controllers thin, delegating business logic to contexts

### LiveComponent Structure
Follow this pattern for LiveComponents:
1. Use `attr` declarations for required properties
2. Implement `update/2` for initial state setup
3. Handle events with `handle_event/3`
4. Use callback functions (like `on_finish`) for parent communication

### Form Handling
- Use `to_form/1` for changeset-to-form conversion
- Process special inputs (like city selection) before submission
- Always handle both `:new` and `:edit` actions in the same form component

### Testing Guidelines
- **Test Public APIs**: Focus on testing public context APIs
- **Mox for Dependencies**: Use Mox for mocking external dependencies
- **Arrange-Act-Assert**: Structure tests with clear setup, action, and verification phases
- Use fixtures for test data from `test/support/fixtures/`
- After any change to a test file run it with `mix test <file_path>`
- After several changes run all tests with `mix test`

### HTTP and API Integration
- **Req for HTTP Clients**: Use Req instead of HTTPoison or Tesla
- **Behaviours for API Clients**: Define behaviours for API clients to allow easy mocking
- **Error Handling**: Handle network failures and unexpected responses gracefully
- **Timeouts**: Always set appropriate timeouts for external calls

### UI and Styling
- Use Phoenix LiveView for dynamic, real-time interactions
- Implement responsive design with Tailwind CSS
- **Petal Components**: Primary UI component library
- **Heroicons**: Icon library from Tailwind
- **Live Select**: Enhanced select components

### Internationalization
- Use `gettext/1` for all user-facing strings
- Supported locales: English (en) and Russian (ru)
- Run `mix gettext` to extract and merge translations

## Contexts
- **Accounts** - Authentication with locale and avatar support
- **Planning** - Travel plans with destinations, accommodations, transfers, expenses
- **Packing** - Packing lists with categorized items and templates
- **Geo** - Countries, regions, cities from GeoNames
- **Social** - Social connections between users

## Deployment
Configured for Fly.io deployment with Docker. Configuration in `fly.toml`.
