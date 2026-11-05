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
- How does this interact with the household manager role (e.g. private chefs managing several households, see the roadmap's Phase 5)? Is a manager an owner, or something else?

**Revisit when:** building Phase 5 (household sharing), before more than one person can edit a household's plan.

## Saved grocery lists when the plan changes

**Decided:** 2026-11-05, during Phase 4 (grocery lists). Nothing built yet.

**What we built**
- `GET /api/v1/grocery_list` works the list out from the planned meals on every request, so it always matches the current plan. Nothing is stored yet.

**Open question**
- Once lists are saved (check-off, "already have", manual items), what happens when the plan changes afterwards? Options:
  - **Update automatically:** recompute the generated items and keep check marks, "have it" flags and manual items. Always current, but quantities can change under someone who is mid-shop.
  - **Snapshot:** the list stays as generated until the user regenerates it. Predictable, but can go stale without anyone noticing.
  - **Snapshot plus a nudge:** keep the snapshot and flag that the plan changed since it was made, so the user can choose to regenerate.

**Revisit when:** building saved grocery lists (Phase 4, slice 2).
