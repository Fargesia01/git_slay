FROM elixir:latest AS builder

RUN apt-get update && apt-get install -y \
  build-essential\
  curl \
  git

ENV MIX_ENV=prod
ENV LANG=C.UTF-8

WORKDIR /app

COPY mix.exs mix.lock ./ 

RUN mix local.hex --force && mix local.rebar --force

RUN mix deps.get 

COPY . .

RUN mix deps.compile && mix compile

RUN mix release

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y libssl-dev openssl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/appuser appuser
ENV MIX_ENV=prod \
  LANG=C.UTF-8 \
  REPLACE_OS_VARS=true

WORKDIR /home/appuser/server

COPY --from=builder /app/_build/prod/rel/server ./ 

RUN chown -R appuser:appuser /home/appuser/server

USER appuser

EXPOSE 5000

CMD ["bin/server", "start"]
