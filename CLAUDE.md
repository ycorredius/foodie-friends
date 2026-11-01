# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 8.0 app (Ruby 3.2.2, see `.ruby-version`; the README's "2.7.2" is out of date) on PostgreSQL. Frontend is server-rendered ERB with Hotwire (Turbo + Stimulus via importmap) and Tailwind CSS. Deployed to Render (`render.yaml`, build script `bin/render-build.sh`). Caching uses Solid Cache and production Action Cable uses Solid Cable (both replaced Redis).

## Commands

```bash
bin/setup                          # install deps, prepare DB
foreman start -f Procfile.dev      # rails server + Tailwind watcher (bin/dev only starts the rails server)
yarn build:css                     # one-off Tailwind build into app/assets/builds/application.css

bundle exec rspec                                   # full suite (what CI runs)
bundle exec rspec spec/models/user_spec.rb          # one file
bundle exec rspec spec/models/user_spec.rb:42       # one example

bundle exec standardrb             # lint (CI runs Standard Ruby, no autofix)
bundle exec standardrb --fix
```

CI (`.github/workflows`) runs on PRs to `main`: Standard lint + `bundle exec rspec` against Postgres.

## Tests

The canonical suite is **RSpec in `spec/`** (FactoryBot, factories in `spec/factories`). The `test/` directory is legacy Minitest code with fixtures that CI does not run; don't add new tests there.

## Architecture

**Two interfaces over the same models:**
- **HTML app** — controllers in `app/controllers/` (plus `app/controllers/user/` for the current user's friends/recipes/invitations), routes in `config/routes.rb`. Auth via Devise session; `ApplicationController` permits extra Devise sign-up params (`first_name`, `last_name`, `avatar`). Pagination via Pagy.
- **JSON API** — `Api::V1::*` controllers under `app/controllers/api/v1/`, routes in `config/routes/api.rb` (loaded via `draw :api`). All inherit `Api::BaseController`, which skips CSRF and authenticates with a bearer token from the `Authorization` header looked up in `ApiToken` (tokens expire 12h after creation). Responses use `fast_jsonapi` serializers in `app/serializers/` and jbuilder views in `app/views/api/`.

**Friendships** are modeled by `Invitation` (`user_id` → `friend_id`, `confirmed` flag) rather than a join table. A friendship can exist in either direction, so `User#friends` and the `Invitation.confirmed_record?` / `pending_invitation` / `find_invitation` helpers always check both orderings — preserve that when touching friend logic.

**Recipe ingredients** are created through service objects in `app/interactors/` (e.g. `AddRecipeIngredients`, `CreateRecipeIngredients`) called from `RecipesController#create/update`. They `find_or_create` the shared `Ingredient` by name and create a `RecipeIngredient` (quantity/unit) join row, returning a `Result` object with `created?`/`errors`.

**Images** use Active Storage with named variants (e.g. `User#avatar` has `:icon`, `:thumb`, `:jumbo`); `google-cloud-storage` is available but production currently uses the `:local` service.

**Databases:** production is a single Postgres DB (Render's `DATABASE_URL`); the Solid Cache and Solid Cable tables live in it and are created by regular migrations in `db/migrate`. Development also defines a separate `cache` database (`db/cache_schema.rb`). Model files carry `annotate` schema comments.

## Design

Brand palette (from README): primary `#1D5B79`, secondary `#468B97`, tertiary `#EF6262`, quaternary `#F3AA60`.
