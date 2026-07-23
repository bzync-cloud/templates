FROM ruby:3.4-alpine
WORKDIR /app
RUN apk add --no-cache build-base
COPY Gemfile* ./
RUN bundle install
COPY . .

# The platform-generated Dockerfile for lang=ruby framework=worker has no
# EXPOSE at all (see rubyDockerfile() in platform/build) — deliberately
# correct for a plain sleep loop, but this template's worker.rb now runs
# an HTTP status server (WEBrick) alongside the loop (see BZYNC_CLOUD), so
# it ships its own Dockerfile to declare that port instead.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

# bundle exec, not plain `ruby worker.rb` — `bundle install` puts gems
# under /usr/local/bundle, which plain `ruby` doesn't know to look in.
# Also true of the platform's own generated Dockerfile for lang=ruby
# framework=worker (see cron/ruby's Dockerfile comment for how this was
# confirmed).
CMD ["bundle", "exec", "ruby", "worker.rb"]
