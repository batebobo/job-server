FROM bitwalker/alpine-elixir:latest as build
COPY . .
RUN export MIX_ENV=dev && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

EXPOSE 3000

ENTRYPOINT ["_build/dev/rel/job_server/bin/job_server", "start"]