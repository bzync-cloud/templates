FROM ruby:3.4-alpine
WORKDIR /app
# tzdata: rufus-scheduler's et-orbi/tzinfo dependency needs actual
# timezone data files on disk, which alpine doesn't ship by default —
# without it, `require "rufus-scheduler"` fails at boot with
# TZInfo::DataSourceNotFound. Also true of the platform's own generated
# Dockerfile for lang=ruby framework=cron (rubyDockerfile() in
# platform/build uses the same ruby:%s-alpine base with no tzdata).
RUN apk add --no-cache build-base tzdata
COPY Gemfile* ./
RUN bundle install
COPY . .

# The platform-generated Dockerfile for lang=ruby framework=cron has no
# EXPOSE at all (see rubyDockerfile() in platform/build) — deliberately
# correct for a plain scheduler loop, but this template's job.rb now runs
# an HTTP status server (WEBrick) alongside the loop (see BZYNC_CLOUD), so
# it ships its own Dockerfile to declare that port instead.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

# bundle exec, not plain `ruby job.rb` — `bundle install` puts gems under
# /usr/local/bundle, which plain `ruby` doesn't know to look in, so
# `require "rufus-scheduler"` (and the other Gemfile gems) fails to load
# without it. This was already true of the platform's own generated
# Dockerfile for lang=ruby framework=cron (see rubyDockerfile() in
# platform/build) — confirmed by building this image with a plain `CMD
# ["ruby", "job.rb"]` first: LoadError on rufus-scheduler.
CMD ["bundle", "exec", "ruby", "job.rb"]
