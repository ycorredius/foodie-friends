# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 8.1 on Ruby 4.0.9 (`.ruby-version`), PostgreSQL, Hotwire (Turbo + Stimulus via importmap), Tailwind via `tailwindcss-rails`, Propshaft. Authentication is Rails' built-in generator (`has_secure_password`), not Devise. No hosting provider has been chosen yet.

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
- **Account deletion is deactivation.** `User#deactivate!` sets `deactivated_at` and destroys all sessions; signing in (web or API) calls `User#reactivate`. Deactivated users' content must be hidden from others (see `Recipe.visible_to`, which filters by `User.active`); apply the same rule to new user-owned content. `PurgeDeactivatedUsersJob` (daily, `config/recurring.yml`) permanently destroys users deactivated longer than `User::DELETION_GRACE_PERIOD` (30 days), so `dependent: :destroy` on user associations is what deletes their data.
- `Current.session` / `Current.user` hold the authenticated session/user in both stacks. Web controllers require auth by default (`allow_unauthenticated_access` to opt out); API controllers likewise via their own `allow_unauthenticated_access`.

**JSON API** lives under `Api::V1` (`config/routes.rb` `namespace :api`), rendered with jbuilder views in `app/views/api/v1/`. New features are API-only for now (no new web pages). `Api::V1::BaseController` turns `RecordNotFound` into a JSON 404; scope lookups through `Current.user` (`Current.user.recipes.find`) or `Recipe.visible_to(Current.user)` so other users' records 404. Lists use the pagination helpers in `Api::V1::BaseController`: `paginate` (Pagy keyset, newest first by id) by default, or `paginate_by_page` (Pagy countless, page numbers) for orders keyset can't follow, like save counts computed at query time. Both set `@next_page` (a string) for views to render as `next_page`; clients send it back as `page` without caring which mode produced it.

**Households and meal planning.** Every user gets a `Household` at sign-up (`User#create_default_household`) through a `HouseholdMembership`; one household per user for now (unique index on `household_memberships.user_id`), and a household is deleted with its plans when its last member leaves. `PlannedMeal` belongs to the household and stores a date and `meal_slot`: there is no week record, so a week is just `User#week_containing(date)` (per `week_start_day`) and changing the setting never moves meals. Plan only recipes the user can see; meals whose recipe later becomes hidden render as `unavailable` (see `planned_meals/_planned_meal`). Always scope planned meals through `Current.user.household`. Each recipe appears once per household, date and slot (unique index; repeated adds return the existing meal), and `PlannedMeal` uses optimistic locking: `PATCH` requires `lock_version` and answers `409` when stale.

**Open questions** live in `docs/THINGS_TO_REVIEW.md`: decisions we made with ideas to revisit later (e.g. roles and approval for shared-household edits). Check it before building the feature an entry names.

**Saves, popularity and forks.** `SavedRecipe` maintains `recipes.saves_count` via counter cache; `Recipe.by_popularity` sorts by it, or by saves within a `POPULARITY_PERIODS` window via a joined subquery. `Recipe#fork_for` copies `FORKED_ATTRIBUTES` and ingredient lines (never the photo) into an `only_me` recipe with `forked_from` set; `forked_from` is only rendered when the original is still visible to the reader. Recipe views compute `@saved_recipe_ids` once per response for the `saved` flag. Recipes without a photo render the placeholder in `app/assets/images/recipe_placeholder*.png` (replace those files to change it).

**Search and discovery.** `recipes.searchable` is a Postgres generated `tsvector` column (title A, description B, ingredient names C) with a GIN index. Ingredient names live in another table, so `Recipe` copies them into `recipes.ingredient_names` in a `before_save`; keep that callback when changing how ingredient lines are saved. `RecipeSearch` parses and validates the explore filters. Results are ordered newest-first (not by relevance) to keep keyset pagination. `GET /api/v1/feed` (`Recipe.feed_for`) excludes the user's own recipes by design.

**Profiles and follows.** `Follow` (follower → followed) is `pending` for private profiles until approved, `accepted` otherwise; `User#follow`/`#unfollow` handle both. Making a profile public approves pending requests. `User.content_visible_to(viewer)` is the single privacy rule (active users with public profiles, plus private ones the viewer follows) and drives `Recipe.visible_to`; reuse it for any new user-owned content and for follower lists (`User#content_visible_to?`).

**Recipes and units.** `Recipe` has many ordered `RecipeIngredient` lines, each pointing at a shared `Ingredient` catalog entry found or created by normalized name. `Recipe#ingredient_lines=` replaces all lines; the association uses `validate: false` because `ingredient_lines_are_valid` validates lines itself so errors are keyed by position in the submitted list (`ingredients[1].unit`). Units are defined in code (`app/models/unit.rb`), not the database: quantities are stored as the author wrote them, and `Unit.convert` scales and converts weight/volume into the reader's `User#unit_system` at render time. Count units are never converted.

**Photos** use Active Storage direct uploads (`Api::V1::DirectUploadsController`), stored on local disk until a cloud provider is chosen; switching is a `config/storage.yml` change. The uploader's id is stored in the blob's metadata, and `RecipesController#uploaded_photo` only attaches blobs the current user uploaded that aren't attached elsewhere. Signed ids appear in public photo URLs, so never attach a blob from a signed id without that check. `PurgeUnattachedUploadsJob` deletes abandoned uploads daily. Thumbnails need the libvips system library plus the `ruby-vips` gem (`require: false`, so the app still boots without libvips); `image_processing` 2.x no longer pulls `ruby-vips` in.

**Seeds** (`db/seeds.rb`) must stay idempotent and production-safe; `spec/db/seeds_spec.rb` enforces this. Data lives in `db/seeds/*.yml`: every ingredient a seed recipe uses must be listed in `ingredients.yml` with a category (the spec checks). Starter recipes belong to the `kitchen@foodiefriends.example` account, which has a random password; the `demo@example.com` login is created in development only.

**Single database.** Solid Cache, Solid Queue and Solid Cable all live in the primary DB, so production needs only one Postgres database: their tables come from regular migrations in `db/migrate` (not `db/*_schema.rb`), and nothing uses `connects_to`. Keep it that way when upgrading these gems — new Solid* schema changes must be added as migrations. In production Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA`).

**Production env vars:** `DATABASE_URL`, `RAILS_MASTER_KEY` (matches the local, gitignored `config/master.key`), `APP_HOST` (mailer link host). Outbound email delivery is not configured yet, so password-reset emails aren't sent in production. Active Storage image variants need libvips on the host.

## Design

Brand palette: primary `#1D5B79`, secondary `#468B97`, tertiary `#EF6262`, quaternary `#F3AA60`.
