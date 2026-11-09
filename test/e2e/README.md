# Chromium end-to-end tests

With the Mix dependencies and local PostgreSQL available, run from the repository root.

```sh
npm ci --prefix test/e2e
(cd test/e2e && npm exec -- playwright install chromium)
MIX_ENV=test mix test.e2e
```

The cover checks use ImageMagick's `convert` with JPEG and HEIC support.
Set `E2E_CHROMIUM` to the absolute path of a local Chromium executable to use it
for both Playwright and PDF rendering.

The task builds the assets and starts a loopback Phoenix server on an ephemeral
port. Each run uses test database fixtures rolled back by the SQL sandbox and
a temporary directory for uploaded covers. Playwright saves traces for failed
scenarios in `test/e2e/test-results/`. Run `mix test` for the regular suite.

The JPEG and HEIC fixtures are synthetic two-color images. The JPEG has EXIF
orientation 6, and the HEIC has a landscape aspect ratio.
