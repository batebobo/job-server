FROM bitwalker/alpine-elixir:latest as build
COPY . .
RUN export MIX_ENV=dev && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

#Set default entrypoint and command
ENTRYPOINT ["_build/dev/rel/job_server/bin/job_server", "start"]