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

List endpoints return newest first unless noted, 20 items by default. Pass `limit` (max 50) for a different page size, and pass the previous response's `next_page` as `page` to get the next page; `next_page` is `null` on the last page. Treat `next_page` as an opaque string.

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/registration` | — | Sign up. Body: `{user: {first_name, last_name, email_address, password, password_confirmation}}`. Returns `{token, user}`. |
| `POST` | `/api/v1/session` | — | Sign in. Body: `{email_address, password}`. Returns `{token, reactivated, user}`; `reactivated` is true when signing in restored a deactivated account. Rate limited. |
| `DELETE` | `/api/v1/session` | ✓ | Sign out (revokes the token used). |
| `GET` | `/api/v1/me` | ✓ | The current user. |
| `PATCH` | `/api/v1/me` | ✓ | Update `{user: {first_name, last_name, unit_system, private_profile}}`. `unit_system` is `us_customary` (default) or `metric`. Making a profile public approves pending follow requests. |
| `DELETE` | `/api/v1/me` | ✓ | Delete your account. Body: `{password}`. Deactivates it and signs out everywhere; returns `{deletes_at}`. Signing in before then reactivates it; after 30 days it's deleted permanently. Rate limited. |
| `GET` | `/api/v1/recipes` | ✓ | Explore: recipes visible to you, with optional search and filters (below). Returns `{recipes, next_page}`. |
| `POST` | `/api/v1/recipes/:id/save` | ✓ | Save a recipe you can see. Returns `{saved, saves_count}`. |
| `DELETE` | `/api/v1/recipes/:id/save` | ✓ | Unsave. |
| `GET` | `/api/v1/me/saved_recipes` | ✓ | Your saved recipes, most recently saved first; ones that became hidden from you are left out. Returns `{recipes, next_page}`. |
| `POST` | `/api/v1/recipes/:id/fork` | ✓ | Copy a recipe you can see into your recipes, as `only_me`, to adapt it. The photo isn't copied. Returns the new recipe, with `forked_from`. |
| `GET` | `/api/v1/feed` | ✓ | Public recipes from people you follow (not your own). Returns `{recipes, next_page}`. |
| `GET` | `/api/v1/recipes/:id` | ✓ | A recipe with steps and ingredients. Optional `servings` scales quantities. |
| `POST` | `/api/v1/recipes` | ✓ | Create. Body below. |
| `PATCH` | `/api/v1/recipes/:id` | ✓ | Update your recipe. Sending `ingredients` replaces all ingredient lines. |
| `DELETE` | `/api/v1/recipes/:id` | ✓ | Delete your recipe. |
| `GET` | `/api/v1/users?q=` | ✓ | Find people by name. Returns `{users, next_page}`. |
| `GET` | `/api/v1/users/:id` | ✓ | A profile: `id`, names, `private_profile`, `followers_count`, `following_count`, `recipes_count` (visible to you), `follow_status` (`accepted`, `pending` or `null`), `follows_you`. |
| `POST` | `/api/v1/users/:id/follow` | ✓ | Follow, or request to follow a private profile. Returns `{status}`: `accepted` or `pending`. |
| `DELETE` | `/api/v1/users/:id/follow` | ✓ | Unfollow, or cancel a pending request. |
| `GET` | `/api/v1/users/:id/followers`, `/following` | ✓ | Returns `{users, next_page}`. A private profile's lists are `403` unless you're an approved follower. |
| `GET` | `/api/v1/me/follow_requests` | ✓ | Users who requested to follow you. Returns `{users, next_page}`. |
| `POST` | `/api/v1/me/follow_requests/:user_id/approve` | ✓ | Approve a request. |
| `DELETE` | `/api/v1/me/follow_requests/:user_id` | ✓ | Decline a request. |
| `DELETE` | `/api/v1/me/followers/:user_id` | ✓ | Remove a follower. |
| `POST` | `/api/v1/direct_uploads` | ✓ | Start a photo upload. Body: `{blob: {filename, byte_size, checksum, content_type}}`. Returns `{signed_id, direct_upload: {url, headers}}`. Rate limited. |

### Recipes

```json
{"recipe": {
  "title": "Pancakes", "description": "Fluffy.", "servings": 4,
  "prep_minutes": 10, "cook_minutes": 15,
  "meal_type": "breakfast", "difficulty": "easy", "visibility": "public",
  "steps": ["Mix.", "Cook."],
  "tags": ["vegetarian", "quick"],
  "ingredients": [
    {"name": "flour", "quantity": 2, "unit": "cup", "note": "sifted"},
    {"name": "salt", "note": "to taste"}
  ]
}}
```

- `meal_type`: breakfast, lunch, dinner, snack, dessert, appetizer, side, drink. `difficulty`: easy, medium, hard. `visibility`: public, only_me.
- `tags`: chosen by the author; lowercased and de-duplicated, at most 10 tags of 30 characters each.
- **Search and filters** on `GET /api/v1/recipes` (all optional, combined with AND):
  - `q`: full-text search over title, description and ingredient names. Matches word forms ("pancake" finds "pancakes") and supports `"quoted phrases"`, `OR`, and `-excluded` words.
  - `meal_type`, `difficulty`: one of the values above.
  - `max_total_minutes`: prep + cook time at most this long. Recipes with no times are excluded.
  - `tags`: recipes with all of these tags, as an array or comma-separated (`tags=vegetarian,quick`).
  - `user_id`: recipes by one author.
  - `sort`: `newest` (default) or `popular` (most saved). With `popular`, `period` is `week`, `month`, `year` or `all` (default) and counts only saves within it. Popular results can shift between pages as saves change.

  Invalid values return `422`. Results are newest first.
- `unit`: g, kg, oz, lb, ml, l, tsp, tbsp, fl_oz, cup, pint, quart, gallon, or a count unit (each, clove, slice, can, package, bunch, sprig, stick, pinch, dash). Quantity and unit may both be omitted.
- Responses convert weights and volumes to the reader's `unit_system` and scale to the requested `servings`; each ingredient's `original` holds the amount as written. Count units are scaled but never converted.
- Validation errors return `422` with `{errors: {field: [messages]}}`; ingredient errors are keyed by position, e.g. `ingredients[1].unit`.

### Photos

Photos are JPEG, PNG or WebP, up to 10 MB. Attaching one takes three steps:

1. `POST /api/v1/direct_uploads` with the file's name, size in bytes, base64-encoded MD5 `checksum`, and content type.
2. `PUT` the raw file bytes to the returned `direct_upload.url`, sending `direct_upload.headers`.
3. Send the returned `signed_id` as `recipe.photo` when creating or updating a recipe. Send `"photo": null` to remove the photo.

You can only attach photos you uploaded yourself, and each upload can be attached to one recipe. Uploads that are never attached are deleted after a day. Recipe responses always include `photo: {thumbnail_url, url, default}` (400px and 1200px versions). Recipes without a photo get a placeholder image with `default: true`.

Recipe responses also include `saves_count` and `saved` (whether you saved it). A recipe's detail view includes `forked_from: {id, title, author}` when it's a copy of a recipe you can still see, otherwise `null`.

## Deployment

No hosting provider has been chosen yet. Wherever it runs, production needs:

- **Environment:** `DATABASE_URL` (one Postgres database), `RAILS_MASTER_KEY` (from `config/master.key`), `APP_HOST` (the domain used in email links), and `SOLID_QUEUE_IN_PUMA=true` to run background jobs inside the web server (or run `bin/jobs` as a separate process).
- **Build:** `bundle install`, `bin/rails assets:precompile`, `bin/rails db:prepare`.
