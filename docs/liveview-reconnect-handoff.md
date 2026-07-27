# LiveView Resilience Handoff

## Repository State

The previous reconnect and offline experiment is not in the working tree. It is saved as:

```text
stash@{0}: On master: WIP LiveView reconnect and trip form resilience experiments
```

Do not restore this stash wholesale. It contains broad form changes and custom JavaScript approaches that conflict with the smaller design described below.

Useful inspection commands:

```bash
git stash show --stat stash@{0}
git stash show --name-status --include-untracked stash@{0}
git stash show -p --include-untracked stash@{0}
```

## Goals

There are three separate goals. They must be implemented and browser-tested in order. Do not start the next goal until the current one passes its acceptance tests.

### Goal 1: Recover Full-Page Forms

Trip new/edit, backpack new/edit, and every other form rendered as the main content of its own page must retain unsaved field values over a LiveView disconnect and reconnect.

Use Phoenix LiveView's built-in form auto-recovery. Do not add a custom JavaScript draft store or LiveStash for these forms.

### Goal 2: Recover Forms Opened Inside ShowTrip

On the ShowTrip page, both of the following must survive reconnecting:

1. Which nested form is currently open, such as `new transfer` or `edit accommodation`.
2. The unsaved values entered into that form.

Use LiveStash to preserve the server-side state that identifies and reconstructs the open form. Once the same form is rendered after remount, use Phoenix LiveView's built-in form auto-recovery to restore its input values.

LiveStash is not the form draft store. Its purpose here is to make the conditional form exist in the remounted HTML so native form recovery can find it.

Do not put the open form or its values in the URL. Do not add a generic JavaScript form serializer.

### Goal 3: Switch ShowTrip Tabs Offline

When a trip is initially opened online, load the content for the entire ShowTrip page, including every tab. Tab clicks must switch the already-loaded panels entirely on the client so they still work after the connection is lost.

Prefer Phoenix.LiveView.JS commands and normal DOM visibility state. Add no custom JavaScript hook unless a specific requirement cannot be met with LiveView's declarative client commands.

This is not general offline support. The user does not need to open or reload a trip while offline. The requirement is only to switch among the tabs of a trip that was loaded while online.

## Primary Constraint

Achieve all three goals with minimal custom code, especially minimal JavaScript.

The intended stack is:

| Problem | Mechanism |
| --- | --- |
| Full-page form values | Phoenix LiveView form auto-recovery |
| Open ShowTrip form identity | LiveStash |
| Open ShowTrip form values | Phoenix LiveView form auto-recovery |
| Offline ShowTrip tab switching | Eagerly rendered panels plus client-side `Phoenix.LiveView.JS` commands |

The implementation must not introduce sessionStorage form drafts, cached HTML replacement, IndexedDB, a service worker, or an offline renderer.

## Why The Goals Differ

Phoenix automatically recovers a form when the old browser DOM contains an eligible form and the newly mounted LiveView renders a matching form. In practice, the form needs:

- a stable, unique HTML `id`
- a form-level `phx-change`
- a change handler that can rebuild the form from the complete submitted params
- to exist in the HTML produced by the reconnect mount

Full-page forms naturally satisfy the last condition because their route always renders the form.

ShowTrip forms do not. A form such as `new transfer` is conditionally rendered from transient server state. On remount, Phoenix cannot replay values into that form if the new LiveView does not know that it should first render it. LiveStash fills this state gap. Native auto-recovery then handles the form data.

Offline tab switching is independent from reconnect recovery. It works by ensuring every tab panel already exists in the browser and by making the visibility change a client-side operation that does not need the socket.

## Iterative Implementation Plan

### Milestone 1: Full-Page Forms

Inventory every full-page new/edit form, starting with:

- trip new and edit
- backpack new and edit
- other LiveView routes whose primary content is a form

For each form:

1. Confirm it has a stable, unique `id`.
2. Confirm it has a form-level `phx-change` event.
3. Confirm the event receives all form params and rebuilds the complete changeset/form assign.
4. Use the default recovery event, which reuses `phx-change`.
5. Add `phx-auto-recover` only if the normal change handler cannot reconstruct the form's state. Do not add a duplicate recovery handler by default.
6. Check special controls such as LiveSelect, money inputs, editors, checkboxes, conditional fields, date/time inputs, and uploads.

Test one representative form first. After proving the mechanism in a real browser, apply the same small pattern to the remaining full-page forms.

#### Milestone 1 Acceptance Tests

For every full-page form:

1. Open the form online and modify every kind of field it contains.
2. Disconnect and reconnect with `window.liveSocket.disconnect()` and `window.liveSocket.connect()`.
3. Verify the form remains visible and all unsaved values remain unchanged.
4. Verify normal editing, validation errors, failed submission, successful submission, and cancel still work.
5. Repeat using a real server interruption without triggering the development live reloader.

Do not begin Milestone 2 until these checks pass.

### Milestone 2: ShowTrip Forms

Integrate LiveStash narrowly into ShowTrip.

1. Define a small, serializable representation of the open form, sufficient to render the same component after remount. It may include form type, mode, record id, and parent/day id as required.
2. Stash that server-side state whenever a ShowTrip form is opened or closed.
3. Restore it during ShowTrip mount before rendering conditional form components.
4. Ensure each nested form has a stable id and a complete form-level `phx-change` handler so native recovery can replay the values.
5. Clear the stashed open-form state on cancel and successful save.
6. Do not stash Ecto changesets or duplicate the browser's form values unless a demonstrated LiveView limitation requires it.

Start with new transfer only. Once it works in the browser, cover edit transfer and then the other ShowTrip forms one at a time.

#### Milestone 2 Acceptance Tests

For each ShowTrip form:

1. Open the form and enter values in all field types.
2. Disconnect and reconnect the LiveSocket.
3. Verify the same form is still open.
4. Verify all unsaved values remain unchanged.
5. Verify custom controls and conditional fields recover correctly.
6. Verify cancel closes the form and clears its stashed identity.
7. Verify successful save closes the form and clears its stashed identity.
8. Verify validation failure leaves the form open with its values.
9. Verify opening a new form later does not restore stale form identity or values.

Do not begin Milestone 3 until these checks pass.

### Milestone 3: Offline ShowTrip Tabs

Change ShowTrip so all tab content is rendered during the initial online page load.

1. Keep every tab panel in the DOM instead of conditionally fetching or rendering only the active tab.
2. Give tab controls and panels stable ids and accessible tab semantics.
3. Switch active-tab styling and panel visibility with client-side `Phoenix.LiveView.JS` commands.
4. Ensure the click does not depend on sending a LiveView event or completing navigation.
5. Keep server-driven updates compatible with the active client-side panel.
6. Do not add HTML prefetching, sessionStorage caching, IndexedDB, a service worker, a sandboxed iframe, or automatic offline reload behavior.

#### Milestone 3 Acceptance Tests

1. Open a trip while online and verify all tab panels are present in the DOM.
2. Disable the network or stop the server.
3. Click every ShowTrip tab and verify the correct already-loaded content appears.
4. Verify tab controls, active styling, focus behavior, and keyboard navigation remain coherent.
5. Restore connectivity and verify the existing LiveView reconnects and continues normally without a forced reload.
6. Verify forms from Milestone 2 still recover after tab switching and reconnecting.

## Rejected Approaches From The Stash

The previous experiment tried several broader mechanisms. They are not part of the target design:

- URL-backed open-form identity
- sessionStorage `TripFormState` form serialization
- sessionStorage `TripTabCache` and cached HTML replacement
- IndexedDB
- service worker
- standalone offline renderer
- sandboxed iframe

The generic form hook caused editing regressions and obscured the behavior of LiveView's built-in recovery. The tab cache introduced inert, stale HTML and unnecessary interaction with LiveView's DOM lifecycle. Do not restore either JavaScript file as a starting point.

One potentially valid isolated change in the stash is the transfer time round-trip fix. A `DateTime` was rendered directly into `<input type="time">`, causing another time field to appear blank after a change event. Extract that fix only if the bug reproduces during the relevant milestone, and keep its regression test with it.

## Test Discipline

Unit and LiveView tests are necessary but do not prove reconnect behavior. Each milestone requires a real browser test that controls the LiveSocket or interrupts the server.

After each small implementation step, run:

```bash
mix format
mix test <focused test files>
mix credo --strict
```

At the end of each milestone, run the full suite and asset build:

```bash
mix test
mix assets.build
```

Keep changes for each milestone separate and reviewable. A passing milestone is the gate for starting the next one.

## References

- [Phoenix LiveView deployments and recovery](https://hexdocs.pm/phoenix_live_view/deployments.html)
- [Phoenix LiveView form bindings and auto-recovery](https://hexdocs.pm/phoenix_live_view/form-bindings.html#recovery-following-crashes-or-disconnects)
- [LiveStash documentation](https://hexdocs.pm/live_stash/)

