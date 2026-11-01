# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 8.1 on Ruby 4.0.9 (`.ruby-version`), PostgreSQL, Hotwire (Turbo + Stimulus via importmap), Tailwind via `tailwindcss-rails`, Propshaft. Authentication is Rails' built-in generator (`has_secure_password`), not Devise. Deployed to Render (`render.yaml`, `bin/render-build.sh`).

This app is a rewrite of an older Devise-based app that lives in `main`'s history before the rewrite commit. Features (recipes, ingredients, friends/invitations, comments, photos) are being ported from it incrementally — look there for the original behavior, but don't copy its patterns wholesale.

## Commands

```bash
bin/setup                     # install gems, prepare DB, start server
bin/dev                       # rails server + Tailwind watcher (foreman, Procfile.dev)

bin/rspec                                  # full suite
bin/rspec spec/models/session_spec.rb      # one file
bin/rspec spec/models/session_spec.rb:12   # one example

bin/standardrb                # lint (Standard Ruby; --fix to autocorrect)
bin/ci                        # everything CI runs: lint, specs, bundler-audit, importmap audit, brakeman
```

Tests are RSpec + FactoryBot (`spec/`); there is no Minitest `test/` directory. The test cache store is `:null_store`, so `rate_limit` never triggers in specs.

## Architecture

**Sessions are the single auth mechanism for both the web app and the JSON API.** `Session` (`app/models/session.rb`) represents a signed-in device:
- Browsers: `Authentication` concern (`app/controllers/concerns/authentication.rb`) stores the session id in a signed permanent cookie.
- API: `Api::V1::BaseController` (`ActionController::API`, no cookies/CSRF) reads `Authorization: Bearer <token>`.
- Only a SHA-256 `token_digest` is stored; the plaintext `Session#token` exists only on the instance that created it, so it must be rendered in that same request (see `api/v1/sessions/create.json.jbuilder`).
- Sessions expire after `Session::TTL` (30 days) without use; `extend_expiry` slides it forward at most once per `REFRESH_INTERVAL` to avoid a write per request. Always look sessions up through `Session.active` / `Session.find_by_token`.
- Password reset destroys all of a user's sessions, which revokes API tokens too.
- `Current.session` / `Current.user` hold the authenticated session/user in both stacks. Web controllers require auth by default (`allow_unauthenticated_access` to opt out); API controllers likewise via their own `allow_unauthenticated_access`.

**JSON API** lives under `Api::V1` (`config/routes.rb` `namespace :api`), rendered with jbuilder views in `app/views/api/v1/`.

**Single database.** Render provides one Postgres database, so Solid Cache, Solid Queue and Solid Cable all live in the primary DB: their tables come from regular migrations in `db/migrate` (not `db/*_schema.rb`), and nothing uses `connects_to`. Keep it that way when upgrading these gems — new Solid* schema changes must be added as migrations. In production Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA`).

**Production env vars** (Render): `DATABASE_URL`, `RAILS_MASTER_KEY` (matches the local, gitignored `config/master.key`), `APP_HOST` (mailer link host). Outbound email delivery is not configured yet, so password-reset emails aren't sent in production. Active Storage image variants need libvips on the host.

## Design

Brand palette: primary `#1D5B79`, secondary `#468B97`, tertiary `#EF6262`, quaternary `#F3AA60`.
