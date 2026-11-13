# Foodie Friends Roadmap

**Mission (refocused 2026-11-13):** help people eat well for less, by showing how cheap cooking at home can be and suggesting meals that fit their budget and food preferences.

**Who it's for:** the family planner: a US household where one person does most of the planning and shopping. Who they are, what the app promises them and how it sounds are in [BRAND.md](BRAND.md).

The app plans a household's week, works out the grocery list, and shows what it costs: per serving, at the checkout, against a weekly budget, and against eating out.

**What makes it different: social around cost.** Budget meal planners are common, and so are recipe-sharing apps. Few combine them. Here, people share whole **priced weeks** ("our $62 week for a family of 4") that others can copy into their own plan, rescaled and re-costed for their household, and the prices users enter combine into **community prices** that make everyone's costs more accurate. Positioning: *see what real people actually spend to eat well, and copy their weeks.*

The app must be useful to someone with no friends on it (budget, costs and suggestions work alone); social multiplies that value rather than being it.

## MVP

**Defined 2026-11-13.** The MVP proves one thing: **a household can see what its week of home cooking costs, stay within a budget, and copy a priced week someone else made.** That's the core (costs and a budget) plus the twist (shared priced weeks), and nothing else.

**Done when** a brand-new user on an Android phone can, in one sitting: sign up, set a weekly budget, copy a starter week, see its cost against their budget and against eating out, get the grocery list and shop with it, and share their own week.

**In the MVP** (items marked **MVP** in the phases below):

| Area | What | Status |
|---|---|---|
| Accounts | Sign up, sign in, sign out, delete account | Built (API) |
| Recipes | Browse, search, recipe detail with servings | Built (API) |
| Plan | Week view, add to plan, copy a week | Built (API) |
| Grocery lists | Preview, save, check off while shopping, **manual items** | Built (API), except manual items |
| Costs | Seeded US price estimates with package sizes; cost per serving; checkout cost; weekly budget; savings against eating out | Phase 5 |
| Shared weeks | Share a week; browse by price and household size; copy, re-costed for your household; seeded starter weeks | Phase 6 |
| Starter content | About 50 cheap seed recipes, so weeks are worth copying | Phase 6 |
| Mobile app | Android only, React Native: Home (this week), Explore (recipes and weeks), Recipe detail, Plan, Groceries, Me with basic settings | Built alongside the API, in its own repo |
| Brand | Name (Kettle & Coin), logo, the Sage & Slate palette, and the Innkeeper's voice in the app's wording, with plain navigation ([BRAND.md](BRAND.md)) | Decided; built with the app |
| Launch | Final name checks; hosting with HTTPS; password-reset emails; an Android release | Phase 7 |

**After the MVP:** regenerating lists when the plan changes; a household's own prices; community prices and regional adjustment; ordering from grocery stores; preferences, allergies and suggestions; follows, profiles and the Following view in the mobile app; social proof and challenges; creating and editing recipes in the mobile app; meal prep; household sharing; iOS.

**Keeping the scope settled:** every product decision ends with an MVP check: it fits in the MVP, it belongs after the MVP, or the MVP is deliberately redefined here (with the date and reason). New ideas default to after the MVP and are parked in [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md) or the later phases.

**MVP checks recorded:**
- 2026-11-13, **theme:** a fantasy tavern feel at "themed world, plain navigation" level (see [BRAND.md](BRAND.md)). The name, logo, voice and a few brand nouns are in the MVP; illustrations, quests and a deeper theme come after it. No change to the MVP's scope.

## Decisions

- **The app is called Kettle & Coin** (chosen 2026-11-13, pending app store, domain and trademark checks), with a fantasy tavern feel and a community called the Hearthguild (see [BRAND.md](BRAND.md)). The Rails app's internal name (`FoodieFriends`) and this repo's name stay as they are.
- **US-focused.** Prices, price data, stores and units default to the US.
- **Prices come in layers.** Seeded US average estimates for every catalog ingredient, so costs show from day one, labelled as estimates. A household's own prices override them. Later, community prices (Phase 9) sit between the two, and store prices (grocer APIs such as Kroger's) may follow. Every cost the API returns says whether it's an estimate and how much of it is missing.
- **Two costs, both shown.** *Cost per serving* counts only what a recipe uses: the "this dinner was $2.10 a plate" number. *Checkout cost* counts whole packages, because you can't buy half an onion; it's what a grocery list costs at the store.
- **Allergies are a strict filter on ingredient data,** never on tags: a suggestion must never contain an allergen the household has listed.
- **Spending stays private.** What can be shared: cost per serving and a shared week's plan total. What is never shown to others: a household's budget, what it spent, or its individual prices. Sharing a week is opt-in and follows the same visibility rules as recipes. Community prices are anonymous averages, published for a region only once enough households have reported a price that no one's purchases can be picked out.
- **Starter weeks come from the app's own kitchen account,** like the starter recipes, and are clearly labelled as from the app: in the brand, they're "the Innkeeper's picks". No fake users.

- **API-first.** Features ship as `/api/v1` endpoints for the mobile client. No new web pages until we decide to build a web UI; the existing pages (sign-in, sign-up, password reset) stay because password-reset emails link to them.
- **Following, with private profiles.** Profiles are public or private. Following a public user takes effect immediately; following a private user sends a follow request they approve or decline.
- **Recipe visibility.** A recipe is visible to everyone if its author is public, to approved followers if the author is private, and always to its author. Each recipe can also be marked "only me" for drafts and personal recipes.
- **Households.** Every user gets a household of one at sign-up. Meal plans and grocery lists belong to the household from the start, so inviting family members later doesn't change how data is stored.
- **Units are a user preference.** Users choose `us_customary` (default) or `metric`. Recipes store quantities as the author wrote them; the server scales and converts weight and volume for each reader. Count units ("2 eggs") are never converted.
- **Lists use keyset pagination** via the Pagy gem (`page` token in, `next_page` out), which suits infinite scroll on mobile.
- **External services wait for the MVP launch** (changed 2026-11-13; previously they waited for a web app). No hosting provider, cloud file storage or email provider has been chosen. Until launch, photos are stored on local disk through Active Storage (switching to cloud storage later is a configuration change), and password-reset emails aren't sent in production.
- **Account deletion is deactivation first.** Deleting an account deactivates it; signing in within 30 days reactivates it, and after that it's deleted permanently.

## Data model

| Entity | Purpose |
|---|---|
| **Recipe** | Title, description, ordered steps, servings, prep/cook time, meal type, difficulty, visibility |
| **Ingredient** | Shared catalog entry ("yellow onion"), with a grocery category; later also allergens and diet flags (e.g. contains meat) |
| **RecipeIngredient** | Quantity + unit + ingredient + note, in order |
| **Follow** | Follower → followed, with status `pending` or `accepted` |
| **Household** | Owns meal plans and grocery lists; has members and a size |
| **PlannedMeal** | A recipe on a date and meal slot for a household, with servings; a week is a date range, starting on the user's chosen day |
| **GroceryList / GroceryItem** | Generated from a meal plan plus manual items; checked off while shopping |
| **Price estimate** (planned) | Seeded US average price for an ingredient, with a typical package size, its source and date |
| **IngredientPrice** (planned) | What a household paid for an ingredient and package size; overrides the estimate for that household |
| **Budget** (planned) | A household's weekly grocery budget, plus the eating-out price it's compared against |
| **Preferences** (planned) | Diets, allergies, disliked ingredients, cuisines and time available, used to filter and suggest meals |

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
- [x] Save a week as a reusable plan template; list, view and delete templates
- [x] Apply a template to a week (plan a whole week in one request)

### Phase 4: Grocery lists

- [x] Generate a list from a meal plan: combine the same ingredient across recipes (converting units where possible), group by store section, show which recipes need each item ([#45](https://github.com/ycorredius/foodie-friends/pull/45))
- [x] Save lists; mark items bought or already had ([#46](https://github.com/ycorredius/foodie-friends/pull/46))
- [ ] **MVP** Manual items
- [ ] "Plan changed" flag and regenerate

### Phase 5: Costs and budgets

The core of the refocused app.

- **MVP** Seeded US average price estimates, with a typical package size, for every catalog ingredient (the seeds spec checks none is missing)
- **MVP** Cost per recipe and per serving in recipe responses, scaled to the servings asked for, marked as estimated, and partial when an ingredient has no price
- **MVP** Grocery list checkout cost (whole packages) and per-item prices
- **MVP** Weekly budget on the household; the week's planned cost against it
- **MVP** Savings against eating out: an adjustable average takeout price per serving
- Household prices: record what you paid, e.g. while checking off a grocery item; they override estimates for that household
- Explore filters and sorting by cost per serving

### Phase 6: Shared priced weeks

The social twist, moved ahead of suggestions (2026-11-13): it needs costs and the plan templates that already exist, not a large user base. Shared weeks are also suggestions picked by people, so they make the app useful before any suggestion algorithm exists.

- **MVP** Share a week: publish a week's plan (built on plan templates) with its total and cost per serving, but never your budget or spending. Visible to followers or everyone, like recipes
- **MVP** Copy a shared week into your own plan in one step, rescaled to your household size and re-costed, with the same no-overwrite rule as templates
- **MVP** Browse shared weeks in Explore by total cost and household size
- **MVP** Starter weeks from the kitchen account, clearly labelled, so there's something to copy on day one
- **MVP** About 50 cheap seeded starter recipes, so the starter weeks have variety
- Following view showing weeks as well as recipes

### Phase 7: MVP launch

- **MVP** Confirm the app name (Kettle & Coin) is available: app stores, domain, trademark
- **MVP** Hosting with HTTPS, and the production database
- **MVP** Email delivery for password resets
- **MVP** An Android release of the mobile app

### Phase 8: Preferences and suggestions

- Preferences: diets, allergies, disliked ingredients, cuisines, time available (see [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md): per person or per household)
- Allergen and diet data on catalog ingredients, seeded and checked by the seeds spec
- Suggest a week: fill chosen days and slots within the budget, from recipes and shared weeks that fit the preferences, preferring meals that share ingredients so packages get used up. A suggestion is a proposal the user reviews, swaps meals in, and then accepts, with the same no-overwrite rule as templates

### Phase 9: Community prices and social proof

These need real users and their prices, so they come once there's real usage.

- Community prices: anonymous regional averages from households' own prices, used as a layer between your prices and the national estimates, published only above a minimum number of households (see [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md))
- Social proof on recipes and weeks, e.g. "cooked by 140 people this month, about $1.90 a serving"
- Later: friendly challenges ("under $50 this week") with friends

### Phase 10: Household sharing

- Invite family members to a household. Users belong to one household at a time: accepting an invite moves them into the new household, and if they were alone in their old one they choose whether to bring their planned meals along or discard them. Leaving a household gives them a fresh household of one.
- Shared meal plans and grocery lists, with live updates via Action Cable. Before building this, review "Editing planned meals in shared households" in [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md) (roles, owner approval).
- Later: a household manager role (e.g. for private chefs) allowing one user to manage several households and switch between them. Regular members stay limited to one household; this relaxes the one-household-per-user rule only for managers and adds a role to memberships.

### Later

- iOS release (cheap with Expo once the Android app works)
- Web UI
- Move photos to cloud storage (S3 or Google Cloud Storage)
- Ordering from grocery stores, and store prices from grocer APIs (see [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md))
- Meal prep (see [THINGS_TO_REVIEW.md](THINGS_TO_REVIEW.md))
- Pantry tracking: what you already have lowers the checkout cost and steers suggestions
- Spending history: what you actually spent over time, against your budget
- Comments, ratings, collections
- Import a recipe from a link (schema.org Recipe data)
- Suggested tags: an API endpoint the app can call while an author tags a recipe, returning tags to offer them. Possible sources: the most-used tags across recipes, matches for what the author has typed so far, and tags inferred from the recipe itself (e.g. "vegetarian" when no ingredient is meat or seafood, "quick" when total time is short). Keeps tags consistent ("quick" instead of "fast" and "speedy").
  - Seed a long curated list of tags (e.g. `db/seeds/tags.yml`) so suggestions work before there's much user data. Possible groups:
    - Diet: vegetarian, vegan, pescatarian, gluten-free, dairy-free, nut-free, low-carb, high-protein
    - Time and effort: quick, under-30-minutes, make-ahead, no-cook, one-pan, one-pot, sheet-pan
    - Cost: pantry-staples, leftovers (whether a recipe is cheap comes from its computed cost, not a tag)
    - Method: slow-cooker, pressure-cooker, air-fryer, grill, baked, stir-fry
    - Occasion: weeknight, weekend, holiday, potluck, picnic, lunchbox
    - Audience: kid-friendly, crowd-pleaser, date-night
    - Cuisine: italian, mexican, chinese, indian, thai, japanese, mediterranean, southern
    - Storage: freezer-friendly, meal-prep
- Notifications
