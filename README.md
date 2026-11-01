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
| `POST` | `/api/v1/session` | — | Sign in. Body: `{email_address, password}`. Returns `{token, user}`. Rate limited. |
| `DELETE` | `/api/v1/session` | ✓ | Sign out (revokes the token used). |
| `GET` | `/api/v1/me` | ✓ | The current user. |

## Deployment

Deployed to Render via `render.yaml`. Set `RAILS_MASTER_KEY` (from `config/master.key`) and `APP_HOST` in the Render dashboard.
