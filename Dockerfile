# Keep the builder and release runtime on the same Debian snapshot.
# scripts/update-production-images maintains these pins.
ARG ELIXIR_VERSION=1.20.5
ARG OTP_VERSION=29.1.2
ARG DEBIAN_VERSION=trixie-20261104-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG NODE_IMAGE="node:22-trixie-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${NODE_IMAGE} AS node

FROM ${BUILDER_IMAGE} AS builder

# install build dependencies
COPY --from=node /usr/local/ /usr/local/
RUN apt-get update -y && apt-get install -y build-essential git \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile
RUN mix localize.download_locales

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y \
  libstdc++6 \
  openssl \
  curl \
  libncurses6 \
  locales \
  imagemagick \
  chromium \
  fonts-dejavu-core \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"
ENV CHROME_BIN="/usr/bin/chromium"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/hamster_travel ./

USER nobody

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=6 \
  CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:4000/up"]

CMD ["/app/bin/server"]
