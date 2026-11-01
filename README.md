# Foodie Friends

Share recipes with friends. Rails 8.1 web app with a JSON API for the mobile client.

## Requirements

- Ruby 4.0.9 (see `.ruby-version`)
- PostgreSQL

## Setup

```bash
bin/setup     # installs gems, prepares the database, starts the server
bin/dev       # later runs: Rails server + Tailwind watcher
```

### Seed data

`bin/rails db:seed` loads the ingredient catalog (`db/seeds/ingredients.yml`) and starter recipes (`db/seeds/recipes.yml`). It's safe to re-run anywhere, including production. `bin/setup` and `db:prepare` only seed a newly created database. In development it also creates a login: `demo@example.com` / `password123`.

## Tests and checks

```bash
bin/rspec       # tests
bin/standardrb  # lint
bin/ci          # everything CI runs
```

## API

All endpoints are under `/api/v1` and speak JSON. Authenticated endpoints take `Authorization: Bearer <token>`. Tokens expire after 30 days without use.

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/registration` | — | Sign up. Body: `{user: {first_name, last_name, email_address, password, password_confirmation}}`. Returns `{token, user}`. |
| `POST` | `/api/v1/session` | — | Sign in. Body: `{email_address, password}`. Returns `{token, reactivated, user}`; `reactivated` is true when signing in restored a deactivated account. Rate limited. |
| `DELETE` | `/api/v1/session` | ✓ | Sign out (revokes the token used). |
| `GET` | `/api/v1/me` | ✓ | The current user. |
| `PATCH` | `/api/v1/me` | ✓ | Update `{user: {first_name, last_name, unit_system}}`. `unit_system` is `us_customary` (default) or `metric`. |
| `DELETE` | `/api/v1/me` | ✓ | Delete your account. Body: `{password}`. Deactivates it and signs out everywhere; returns `{deletes_at}`. Signing in before then reactivates it; after 30 days it's deleted permanently. Rate limited. |
| `GET` | `/api/v1/recipes` | ✓ | Recipes visible to you, newest first. Params: `limit` (max 50), `before` (the previous page's `next_cursor`), `user_id`. Returns `{recipes, next_cursor}`. |
| `GET` | `/api/v1/recipes/:id` | ✓ | A recipe with steps and ingredients. Optional `servings` scales quantities. |
| `POST` | `/api/v1/recipes` | ✓ | Create. Body below. |
| `PATCH` | `/api/v1/recipes/:id` | ✓ | Update your recipe. Sending `ingredients` replaces all ingredient lines. |
| `DELETE` | `/api/v1/recipes/:id` | ✓ | Delete your recipe. |

### Recipes

```json
{"recipe": {
  "title": "Pancakes", "description": "Fluffy.", "servings": 4,
  "prep_minutes": 10, "cook_minutes": 15,
  "meal_type": "breakfast", "difficulty": "easy", "visibility": "public",
  "steps": ["Mix.", "Cook."],
  "ingredients": [
    {"name": "flour", "quantity": 2, "unit": "cup", "note": "sifted"},
    {"name": "salt", "note": "to taste"}
  ]
}}
```

- `meal_type`: breakfast, lunch, dinner, snack, dessert, appetizer, side, drink. `difficulty`: easy, medium, hard. `visibility`: public, only_me.
- `unit`: g, kg, oz, lb, ml, l, tsp, tbsp, fl_oz, cup, pint, quart, gallon, or a count unit (each, clove, slice, can, package, bunch, sprig, stick, pinch, dash). Quantity and unit may both be omitted.
- Responses convert weights and volumes to the reader's `unit_system` and scale to the requested `servings`; each ingredient's `original` holds the amount as written. Count units are scaled but never converted.
- Validation errors return `422` with `{errors: {field: [messages]}}`; ingredient errors are keyed by position, e.g. `ingredients[1].unit`.

## Deployment

No hosting provider has been chosen yet. Wherever it runs, production needs:

- **Environment:** `DATABASE_URL` (one Postgres database), `RAILS_MASTER_KEY` (from `config/master.key`), `APP_HOST` (the domain used in email links), and `SOLID_QUEUE_IN_PUMA=true` to run background jobs inside the web server (or run `bin/jobs` as a separate process).
- **Build:** `bundle install`, `bin/rails assets:precompile`, `bin/rails db:prepare`.
