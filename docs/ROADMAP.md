# Foodie Friends Roadmap

Foodie Friends is a place for families to discover meal ideas, plan their week, and shop for it. Recipes and following people are how users find ideas; meal plans and grocery lists are what make the app useful week to week.

## Decisions

- **API-first.** Features ship as `/api/v1` endpoints for the mobile client. No new web pages until we decide to build a web UI; the existing pages (sign-in, sign-up, password reset) stay because password-reset emails link to them.
- **Following, with private profiles.** Profiles are public or private. Following a public user takes effect immediately; following a private user sends a follow request they approve or decline.
- **Recipe visibility.** A recipe is visible to everyone if its author is public, to approved followers if the author is private, and always to its author. Each recipe can also be marked "only me" for drafts and personal recipes.
- **Households.** Every user gets a household of one at sign-up. Meal plans and grocery lists belong to the household from the start, so inviting family members later doesn't change how data is stored.
- **Units are a user preference.** Users choose `us_customary` (default) or `metric`. Recipes store quantities as the author wrote them; the server scales and converts weight and volume for each reader. Count units ("2 eggs") are never converted.
- **Pricing is stored, not used.** Grocery items can record prices, but there are no budgeting features yet.
- **Lists use cursor pagination** (`before` + `next_cursor`), which suits infinite scroll on mobile.

## Data model

| Entity | Purpose |
|---|---|
| **Recipe** | Title, description, ordered steps, servings, prep/cook time, meal type, difficulty, visibility |
| **Ingredient** | Shared catalog entry ("yellow onion"), with a grocery category |
| **RecipeIngredient** | Quantity + unit + ingredient + note, in order |
| **Follow** | Follower → followed, with status `pending` or `accepted` |
| **Household** | Owns meal plans and grocery lists; has members and a size |
| **MealPlan / MealPlanEntry** | A week; each entry is a recipe in a day and meal slot, with a servings override |
| **GroceryList / GroceryItem** | Generated from a meal plan plus manual items; checked off while shopping |
| **IngredientPrice** | Price a household paid per unit (stored for future budgeting) |

## Phases

### Phase 0: Foundation ✅

Built-in Rails authentication shared by web and API (hashed bearer tokens, 30-day sliding expiry), Solid Cache/Queue/Cable in a single database, Render deployment, CI. ([#29](https://github.com/ycorredius/foodie-friends/pull/29))

### Phase 1: Recipes (in progress)

- [x] Recipe CRUD, structured ingredients, shared ingredient catalog ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [x] Unit preference, server-side conversion, scaling by servings ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [x] Public / only-me visibility ([#32](https://github.com/ycorredius/foodie-friends/pull/32))
- [ ] Recipe photos via Active Storage direct uploads (needs a storage provider: S3 or Google Cloud Storage)
- [ ] Email delivery in production (password reset)
- [x] Account deletion: deactivate, reactivate on sign-in, permanently delete after 30 days
- [x] Seed recipes and ingredient categories

### Phase 2: Social and discovery

- Public/private profile setting
- Follow and unfollow; follow requests with approve, decline, and remove follower
- Making a profile public approves pending requests; making it private keeps existing followers
- Recipe visibility enforced everywhere: feed, Explore, search, profiles
- Feed of recipes from people you follow; Explore (newest, popular)
- Search with filters (meal type, total time, tags), using Postgres full-text search
- Save recipes; copy ("fork") a recipe to adapt it

### Phase 3: Meal planning

- Household of one created at sign-up
- Weekly planner: days × breakfast/lunch/dinner/snack; servings default to the household size
- Copy last week's plan; reusable plan templates

### Phase 4: Grocery lists

- Generate a list from a meal plan: combine the same ingredient across recipes (converting units where possible), group by store section, show which recipes need each item
- Manual items, check off, mark items you already have
- Price storage only (optional price per item, `IngredientPrice`); no budgeting features

### Phase 5: Household sharing

- Invite family members to a household
- Shared meal plans and grocery lists, with live updates via Action Cable

### Later

- Web UI
- Budgeting: cost per recipe and serving, weekly budgets, filtering by cost
- Comments, ratings, collections
- Import a recipe from a link (schema.org Recipe data)
- Notifications, pantry tracking, suggested meal plans
