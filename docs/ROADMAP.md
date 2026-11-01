# Foodie Friends Roadmap

Foodie Friends is a place for families to discover meal ideas, plan their week, and shop for it. Recipes and following people are how users find ideas; meal plans and grocery lists are what make the app useful week to week.

## Decisions

- **API-first.** Features ship as `/api/v1` endpoints for the mobile client. No new web pages until we decide to build a web UI; the existing pages (sign-in, sign-up, password reset) stay because password-reset emails link to them.
- **Following, with private profiles.** Profiles are public or private. Following a public user takes effect immediately; following a private user sends a follow request they approve or decline.
- **Recipe visibility.** A recipe is visible to everyone if its author is public, to approved followers if the author is private, and always to its author. Each recipe can also be marked "only me" for drafts and personal recipes.
- **Households.** Every user gets a household of one at sign-up. Meal plans and grocery lists belong to the household from the start, so inviting family members later doesn't change how data is stored.
- **Units are a user preference.** Users choose `us_customary` (default) or `metric`. Recipes store quantities as the author wrote them; the server scales and converts weight and volume for each reader. Count units ("2 eggs") are never converted.
- **Pricing is stored, not used.** Grocery items can record prices, but there are no budgeting features yet.
- **Lists use keyset pagination** via the Pagy gem (`page` token in, `next_page` out), which suits infinite scroll on mobile.
- **External services wait for a working web app.** No hosting provider, cloud file storage or email provider has been chosen. Until then, photos are stored on local disk through Active Storage (switching to cloud storage later is a configuration change), and password-reset emails aren't sent in production.
- **Account deletion is deactivation first.** Deleting an account deactivates it; signing in within 30 days reactivates it, and after that it's deleted permanently.

## Data model

| Entity | Purpose |
|---|---|
| **Recipe** | Title, description, ordered steps, servings, prep/cook time, meal type, difficulty, visibility |
| **Ingredient** | Shared catalog entry ("yellow onion"), with a grocery category |
| **RecipeIngredient** | Quantity + unit + ingredient + note, in order |
| **Follow** | Follower → followed, with status `pending` or `accepted` |
| **Household** | Owns meal plans and grocery lists; has members and a size |
| **PlannedMeal** | A recipe on a date and meal slot for a household, with servings; a week is a date range, starting on the user's chosen day |
| **GroceryList / GroceryItem** | Generated from a meal plan plus manual items; checked off while shopping |
| **IngredientPrice** | Price a household paid per unit (stored for future budgeting) |

## Phases

### Phase 0: Foundation ✅

Built-in Rails authentication shared by web and API (hashed bearer tokens, 30-day sliding expiry), Solid Cache/Queue/Cable in a single database, CI. ([#29](https://github.com/ycorredius/foodie-friends/pull/29))

### Phase 1: Recipes (in progress)

- [x] Recipe CRUD, structured ingredients, shared ingredient catalog ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [x] Unit preference, server-side conversion, scaling by servings ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [x] Public / only-me visibility ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [x] Seed recipes and ingredient categories ([#34](https://github.com/ycorredius/foodie-friends/pull/34))
- [x] Account deletion: deactivate, reactivate on sign-in, permanently delete after 30 days ([#35](https://github.com/ycorredius/foodie-friends/pull/35))
- [x] Recipe photos via Active Storage direct uploads, stored on local disk for now

### Phase 2: Social and discovery ✅

- [x] Public/private profile setting; user profiles
- [x] Follow and unfollow; follow requests with approve, decline, and remove follower
- [x] Making a profile public approves pending requests; making it private keeps existing followers
- [x] Recipe visibility follows profile privacy (recipe lists, recipe pages, profiles)
- [x] Feed of recipes from people you follow; Explore (newest)
- [x] Search with filters (meal type, difficulty, total time, tags), using Postgres full-text search; recipe tags; find people by name
- [x] Explore sorted by popularity, by week, month, year or all time
- [x] Save recipes; copy ("fork") a recipe to adapt it
- [x] Default placeholder image for recipes without a photo

### Phase 3: Meal planning

- [x] Household of one created at sign-up; household name and size
- [x] Weekly planner: days × breakfast/lunch/dinner/snack, several recipes per slot; servings default to the household size; week start is a user setting (Sunday or Monday)
- [x] Copy last week's (or any week's) plan, refusing to overwrite unless asked
- [ ] Reusable plan templates

### Phase 4: Grocery lists

- Generate a list from a meal plan: combine the same ingredient across recipes (converting units where possible), group by store section, show which recipes need each item
- Manual items, check off, mark items you already have
- Price storage only (optional price per item, `IngredientPrice`); no budgeting features

### Phase 5: Household sharing

- Invite family members to a household. Users belong to one household at a time: accepting an invite moves them into the new household, and if they were alone in their old one they choose whether to bring their planned meals along or discard them. Leaving a household gives them a fresh household of one.
- Shared meal plans and grocery lists, with live updates via Action Cable. Before building this, review "Editing planned meals in shared households" in [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md) (roles, owner approval).
- Later: a household manager role (e.g. for private chefs) allowing one user to manage several households and switch between them. Regular members stay limited to one household; this relaxes the one-household-per-user rule only for managers and adds a role to memberships.

### Later

- Web UI
- Once the web UI works: choose hosting, move photos to cloud storage (S3 or Google Cloud Storage), and set up email delivery for password resets
- Budgeting: cost per recipe and serving, weekly budgets, filtering by cost
- Comments, ratings, collections
- Import a recipe from a link (schema.org Recipe data)
- Suggested tags: an API endpoint the app can call while an author tags a recipe, returning tags to offer them. Possible sources: the most-used tags across recipes, matches for what the author has typed so far, and tags inferred from the recipe itself (e.g. "vegetarian" when no ingredient is meat or seafood, "quick" when total time is short). Keeps tags consistent ("quick" instead of "fast" and "speedy").
  - Seed a long curated list of tags (e.g. `db/seeds/tags.yml`) so suggestions work before there's much user data. Possible groups:
    - Diet: vegetarian, vegan, pescatarian, gluten-free, dairy-free, nut-free, low-carb, high-protein
    - Time and effort: quick, under-30-minutes, make-ahead, no-cook, one-pan, one-pot, sheet-pan
    - Cost: budget, pantry-staples, leftovers
    - Method: slow-cooker, pressure-cooker, air-fryer, grill, baked, stir-fry
    - Occasion: weeknight, weekend, holiday, potluck, picnic, lunchbox
    - Audience: kid-friendly, crowd-pleaser, date-night
    - Cuisine: italian, mexican, chinese, indian, thai, japanese, mediterranean, southern
    - Storage: freezer-friendly, meal-prep
- Notifications, pantry tracking, suggested meal plans
