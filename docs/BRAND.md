# Brand brief

Who the app is for, what it promises and how it sounds. Every screen, message and piece of copy should be checked against this page. It's a working draft: update it as decisions change, with the date.

**Written 2026-11-13.** The mission and product scope are in [ROADMAP.md](ROADMAP.md); this page is about how they come across to people.

**In short:** **Kettle & Coin**, a meal planning and grocery budgeting app with a cozy fantasy tavern feel, for the family planner. Its community is **the Hearthguild**, and its voice is **the Innkeeper**.

## Who it's for

**The family planner:** a US household, often a family, where one person does most of the planning and shopping.
- They already cook sometimes, but spend more on takeout and groceries than they'd like.
- "What's for dinner?" is a daily stress, on top of a busy week.
- They aren't chefs and don't want to become one. They want dinners that work, that the family will eat, at a price that makes sense.
- They're comfortable with phone apps, but have no patience for setup or busywork.

Others will use the app too (couples, young adults starting out, meal preppers), and that's welcome. But when a design choice has to favor someone, it favors the family planner.

## What they get

1. **Money back:** a visible number every week, e.g. "about $85 less than eating out".
2. **Less mental load:** a week planned in minutes, by copying one that already works for a family like theirs.
3. **Confidence:** proof, from real people, that eating well at home is affordable.

## The promise

> **Eating well doesn't have to cost much, and here's proof from people like you.**

What sets it apart: real weeks of meals from real families, with real prices, that you can copy and make your own.

## Personality

**The Innkeeper:** a warm host at a fantasy tavern who knows how to feed a crowd on a few coins, and is happy to share how. Practical first, with a twinkle.

| It is | It isn't |
|---|---|
| Warm, practical, encouraging | A finance app: no spreadsheets, no guilt |
| Proud of simple, hearty, everyday food | A fancy chef, or a food magazine |
| Honest about costs, including estimates | A diet app: no calorie counting or "good" and "bad" food |
| Generous: sharing what works | Pushy: no nagging, no streak pressure |
| Cozy and a little whimsical | A game you have to learn, or a costume party |

## Theme: a themed world, with plain navigation

**Decided 2026-11-13.** The app has a fantasy tavern feel. The theme lives in the name, the look, the Innkeeper's voice and a few brand nouns, while **everything the user needs to get a job done stays in plain words.** A busy parent in a supermarket aisle should never have to translate a label.

The rule: **theme the world, not the controls or the money.**
- **Plain:** tab names (Home, Explore, Plan, Groceries, Me), screen titles for everyday tasks, buttons ("Copy this week", "Add to plan", "Save"), settings, and errors.
- **Money is always plain dollars and cents:** "$64 of $90", never gold pieces. Trust in the numbers is the core of the app.
- **Themed:** the name, logo and look; the Innkeeper's voice in empty states, welcomes and celebrations; and the brand nouns below.

**Brand nouns** (the only themed names, chosen because they explain themselves):

| Brand noun | What it is |
|---|---|
| **The Hearthguild** | The community: everyone who shares their weeks. "Shared by the Hearthguild", "Join the Hearthguild" |
| **The Innkeeper** | The app's own kitchen account and voice. Starter recipes and weeks come from the Innkeeper, clearly labelled |
| **The Innkeeper's picks** | The starter weeks to copy |
| **Bill of fare** | A shared week of meals with its cost ("a $62 bill of fare for a family of 4"). Used alongside plain words ("week") until users know it |

Anything not in this table keeps its plain name. Adding a brand noun is a deliberate decision recorded here.

**Considered and set aside:** a full theme (the grocery list as "Provisions", the budget as a "Coin purse", settings as "Your quarters", the Explore tab as "the Notice Board", challenges as "Quests"). It's memorable, but it adds a translation step to every everyday task and risks putting off people who don't like fantasy. Revisit only if testing with target users shows they understand and prefer it. The app keeps all its wording in one place, so the theme can be deepened later without rebuilding screens.

## Voice and tone

- **Encouraging, never shaming.** Going over budget gets "here are some cheaper swaps", not red warnings or "you overspent".
- **Plain words.** "Cost per serving", not "unit economics". "Copy this week", not "import template".
- **Specific and concrete.** "$2.10 a plate" beats "affordable". "Feeds 4 for $62 this week" beats "budget-friendly".
- **Honest.** Estimated prices are labelled as estimates, and missing prices are admitted ("3 ingredients have no price yet").
- **Short.** The planner is busy: one clear sentence beats a paragraph.
- **Warm, with a twinkle.** The Innkeeper's voice shows up in moments with room for it (empty states, welcomes, celebrations), never in the way of a task. A tavern turn of phrase now and then is charming; one on every screen is tiring.

Examples:

| Situation | Say | Don't say |
|---|---|---|
| Week is over budget | "$12 over this week. Want some cheaper swaps?" | "Warning: budget exceeded!" or "Your coin purse runs dry!" |
| Under budget | "$26 to spare this week. Your purse thanks you." | "Budget remaining: $26.00" |
| Savings | "About $85 less than eating out this week" | "Savings: $85.00" |
| Empty plan | "The hearth is cold. The Innkeeper has a few weeks to get you cooking." | "No data" |
| Estimated price | "About $2.10 a serving (estimated)" | "$2.10" (when it's a guess) |
| Grocery list title | "Groceries" | "Provisions" |
| Error | "Couldn't save your plan. Check your connection and try again." | "Alas, the raven was lost!" |

## Name

**Kettle & Coin** (chosen 2026-11-13), with its community called **the Hearthguild**.
- **Why it fits:** a tavern-sign name ("X & Y") that carries the whole promise: the kettle for home cooking, the coin for money. Warm and family-friendly on an app icon, and distinctive in a category full of plain "budget meal planner" names.
- **Tagline candidates:**
  - "Kettle & Coin: feed your family well, for less"
  - "Kettle & Coin: real meals, real prices, from the Hearthguild"
- **Before it's final:** check the Play Store and App Store, domains (e.g. kettleandcoin.com, kettlecoin.app), and the USPTO trademark search. If the name is taken, the tavern-sign pattern offers close alternatives (e.g. Coin & Cauldron, Hearth & Ledger), and Hearthguild could become the app's name instead.
- **Written as** "Kettle & Coin" in copy; where an ampersand can't be used (domains, package ids, file names), "kettle-and-coin" or "kettlecoin".
- **Considered and set aside:** Potluck (a common word, hard to own), Kinfare, Pinchpot, Copperpot, Forkcast, Homeplate, Quartermaster.

The Rails app's internal name (`FoodieFriends`) and the backend repo's name stay as they are; the name is for users.

## Visual direction

**Palette: Sage & Slate** (chosen 2026-11-13, replacing the old blue and coral palette). Earthy, calm and trustworthy with numbers: a deep slate teal with sage, wheat and terracotta, on soft off-white.

| Color | Hex | Feel |
|---|---|---|
| Slate teal (primary) | `#2F5D62` | Calm and trustworthy, for buttons and numbers |
| Sage (secondary) | `#DBE8D6` | Fresh, garden-grown |
| Wheat (highlight) | `#E9C46A` | Warmth and a little celebration |
| Leaf (savings) | `#3F7A4F` | Money saved, things going well |
| Terracotta (alert) | `#B5523B` | Real problems only, never budgets |

The full light and dark color roles are in [MOBILE_DESIGN.md](MOBILE_DESIGN.md) (section 3).

The palette suits the tavern: slate for stone walls, sage for herbs, wheat for bread and candlelight.

- **Type:** a characterful heading font with a hint of old-world warmth (like a tavern sign), used only for headings and the logo; a clean, highly readable sans-serif for everything else, including all numbers and prices. Choose both once the first screens exist.
- **Logo:** simple for the MVP, e.g. a kettle with a coin, in slate and wheat. It must read at app-icon size.
- Food photos carry the design: everyday, home-cooked food, not styled magazine shots.
- **After the MVP:** illustrations in the tavern world (the Innkeeper, a hearth, a notice board) for empty states and celebrations.
- The palette should be tried on real screens early; small adjustments to exact shades are expected once the Expo app shows them.
