# Things to review

Decisions we made with open questions attached. Each entry records what we decided, why, and the ideas we want to come back to. Revisit them before building the feature named under "Revisit when".

## Editing planned meals in shared households

**Decided:** 2026-11-01, during Phase 3 (meal planning).

**What we built**
- A meal slot can hold several recipes, so adding or moving a meal never replaces what's already there. The only bulk replace, copying a week onto one that has meals, requires `replace: true`.
- Each recipe can be planned only once per date and slot. Adding it again returns the existing meal, so double taps and retries don't create duplicates.
- Optimistic locking: editing a planned meal requires the `lock_version` the app last saw. If someone else changed the meal in the meantime, the edit is rejected with `409 Conflict` and the meal's current state, instead of overwriting their change. Deleting doesn't check the version.

Together these stop accidental overwrites. Every member of a household still has equal power, though: anyone can add, move, change or delete any meal, and the first save wins.

**Open ideas (nothing concrete yet, and not convinced either way)**
- **Roles in a household,** e.g. an owner and members. The owner's choices could override everyone else's.
- **Approval of changes:** members could propose changes to the plan that the owner has to accept before they take effect, rather than changing it directly.
- Or keep it as it is: equal members, conflicts caught by locking. That's simpler, and may be enough for most families.

**Questions to answer**
- Should members be able to edit the plan directly, or only propose changes? Does that differ between adding a meal and changing or removing someone else's?
- If changes need approval, where do pending proposals show up, and what happens if the owner never responds?
- Should deleting a meal also be protected by the version check, or by approval?
- How does this interact with the household manager role (e.g. private chefs managing several households, see the roadmap's Phase 8)? Is a manager an owner, or something else?

**Revisit when:** building Phase 8 (household sharing), before more than one person can edit a household's plan.

## Saved grocery lists when the plan changes

**Decided:** 2026-11-05, during Phase 4 (grocery lists).

**What we decided**
- Saved lists are **snapshots plus a nudge**: a saved list doesn't change when the plan does, so quantities never shift while someone is shopping. Instead the list will show a "plan changed" flag, and a regenerate action will update the generated items while keeping statuses and manual items. Saving and viewing lists are built; the flag and regenerate come in a later PR.
- Rejected: updating lists automatically (quantities could change mid-shop) and snapshots with no flag (lists could go out of date without anyone noticing).

**Open ideas**
- When regenerating, what happens to an item marked bought whose quantity went up? Keep it bought, or reset it to "to buy" for the difference?

**Revisit when:** building the plan-changed flag and regenerate.

## Food preferences: per person or per household

**Decided:** 2026-11-13, when the app was refocused on budgets and suggestions. Nothing is built yet; only the direction is set: suggestions respect diets, allergies, dislikes, cuisines and time available, and allergies are a strict filter on ingredient data.

**Open ideas**
- **Per household:** one set of preferences for the plan. Simple, and the plan is shared anyway, but someone has to merge everyone's needs by hand.
- **Per person, combined for the household:** each member sets their own; suggestions use the union of allergies and diets and avoid anyone's dislikes. More accurate for families, more to build, and it only matters once household sharing (Phase 8) exists.
- A middle path: store preferences per user now, and combine members' preferences when sharing arrives.

**Questions to answer**
- Are dislikes a hard filter (never suggest) or a soft one (suggest less often)?
- Should a member's diet (e.g. one vegetarian in the family) exclude meals for everyone, or suggest a variant for them?

**Revisit when:** building preferences in Phase 6.

## How accurate price estimates need to be

**Decided:** 2026-11-13. Costs start from seeded US national average prices, overridden by a household's own prices; store prices from grocer APIs come later.

**Open ideas**
- National averages can be well off in expensive or cheap areas. A regional adjustment (e.g. by state or ZIP code region, from public price indexes) could help before store prices exist.
- **Community prices** (Phase 7) are the longer-term answer: anonymous regional averages of what households paid. They need a minimum number of reporting households per ingredient and region before they're shown, both for privacy and so one odd price doesn't skew them. What that minimum is, how big a "region" is (state, metro area, ZIP prefix), and how to drop outliers (a typo of $40 for an onion) are still open.
- Estimates go stale: record each one's source and date, and decide how often to refresh them.
- Show how confident a cost is, e.g. "estimated" vs. "your prices", and "3 of 9 ingredients have no price".

**Questions to answer**
- Is a national average good enough for the first release, or is a regional adjustment needed to keep users' trust?
- Where should a household's own prices come from first: entered while checking off a grocery item, typed in on an ingredient, or both?

**Revisit when:** building price estimates in Phase 5.

## Meal prep

**Decided:** nothing yet. Raised 2026-11-13 as an idea to think through before it goes on the roadmap. Many people cook a batch of meals for the whole week on one day; it fits the budget mission well, because batch cooking and buying in bulk are among the biggest real savings and waste less food.

**Idea so far: separate when you eat from when you cook**
- Keep the plan as *what you eat when*: planned meals stay one recipe on a date and slot, with servings.
- Add a **prep session** on top: a day on which the household cooks batches that cover a set of planned meals (e.g. Sunday: burrito bowls ×5 for Mon–Fri lunch, chili ×4 for four dinners).
- Grocery lists, costs, budgets and suggestions all read the plan, so they'd keep working unchanged; plan templates and shared weeks would carry prep weeks too.

**What it could add**
- A **prep day view:** each recipe scaled to its full batch, and how to portion it ("5 containers: Mon–Fri lunch").
- A **prep week view** (the week's menu): the meals made for that week, with how many portions of each are left, which days and slots they're for, and links to their recipes. During the week it answers "what's in the fridge, and what's for lunch today?"; portions could be ticked off as they're eaten.
- A **gather ingredients screen** for prep day: everything to take out before cooking, each ingredient combined across all the session's recipes (e.g. "garlic: 9 cloves") with the split per recipe underneath, ticked off as it's set out. It's different from the grocery list: the grocery list is what to *buy* (whole packages, by store aisle), this is what to *use* (exact amounts, perhaps grouped by where it's kept: fridge, pantry, freezer). It reuses the grocery list's way of combining amounts, and could also be useful for cooking a single recipe, not just prep days.
- **How long food keeps:** fridge life and whether a recipe freezes well, as structured recipe data (not tags, since the app calculates and warns with them). Warn when a meal would be eaten after its fridge life and suggest freezing those portions. Food safety guidance must come from a reliable source such as USDA.
- **Prep mode for suggestions:** fewer recipes that batch well and share ingredients, cooked on the chosen prep day(s).
- **Shared prep weeks** ("Sunday prep: 15 meals, $38, about 2½ hours") as Community content (Phase 7).

**Questions to answer**
- One prep day a week, or several (e.g. Sunday and Wednesday, so food stays fresh)? Which should the first design focus on?
- Do preppers mostly eat the same meal several days running, or prep **components** (a protein, a grain, roasted vegetables) and mix them into different meals? Components would need a different model than whole recipes.
- How strict should fridge-life handling be: a gentle note, or a clear warning that suggests freezing?
- Does prep time matter enough to estimate a session's total time, and can steps from different recipes be combined into one cooking order, or is that too complex?
- Should the prep week view track portions eaten (tick off "Monday's lunch"), or only show what was made? Tracking is more useful but asks the user to do something every day.
- Should the gather screen be grouped by recipe (cook one at a time) or by where ingredients are kept (one trip to the fridge, one to the pantry)? This needs a storage location on catalog ingredients, which doesn't exist yet.
- Where should it sit in the roadmap? One idea: a small phase right after costs (Phase 5), so suggestions (Phase 6) can include prep mode from the start.

**Revisit when:** the meal prep research is done, before planning Phase 6 (suggestions), since prep mode affects how suggestions are built.
