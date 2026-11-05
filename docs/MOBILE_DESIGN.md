# Mobile app design

The design for the Foodie Friends mobile client: structure, screens, the experience on each, visual design and build order. It's a working draft: update it as decisions change.

**Decided (2026-11-05):**
- **Native Android first,** in Kotlin with Jetpack Compose, in a separate repo, tested on an Android phone.
- **A native iOS app in Swift later.** The screens and experience here apply to both; platform conventions differ in places (section 6).
- **Built by hand** by the project owner. This document describes *what* to build and *why*, not how to code it.

## 1. App structure

A **bottom navigation bar** (the Android standard, 3–5 tabs) with five tabs:

| Tab | Purpose | API |
|---|---|---|
| **Home** | Recipes from people you follow | `GET /api/v1/feed` |
| **Explore** | Search and discover recipes | `GET /api/v1/recipes` with filters |
| **Plan** | The week's meals | `meal_plans`, `planned_meals`, `plan_templates` |
| **Groceries** | Shopping lists | `grocery_lists` |
| **Me** | Your recipes, saved recipes, followers, settings | `me`, `saved_recipes`, `follow_requests` |

**Adding a recipe** is a floating "+" button on Home and Me, not a tab: it's occasional, while browsing and planning are daily.

Screens opened on top of the tabs:
- Recipe detail
- Recipe editor
- Another user's profile
- Add to plan (bottom sheet)
- Settings

## 2. Screens

### Sign in / sign up

- Short and friendly. Sign-up asks for first name, last name, email and password only.
- After sign-up, a **skippable three-question setup**: units (US or metric), the day your week starts, and how many people you cook for. Each one makes the app feel right from the start: amounts appear in the right units, the planner starts on the right day, and planned meals default to the right servings.

### Home (feed)

- Large recipe cards: photo (or the placeholder), title, author, save button.
- Infinite scroll: fetch the next page with `next_page` as the user nears the bottom. Pull down to refresh.
- **Empty state:** a new user follows nobody, so the feed starts empty. Show "Find people to follow" and popular recipes instead of a blank screen.

### Explore

- Search bar at the top (`q`).
- Filter chips below it:
  - meal type (`meal_type`)
  - difficulty (`difficulty`)
  - time, e.g. "under 30 min" (`max_total_minutes`)
  - tags (`tags`)
- A Newest / Popular toggle (`sort`). Popular has a This week / Month / Year / All time picker (`period`).
- Results use the same cards as Home, so the app feels consistent.

### Recipe detail

- Photo at the top, then title, author and times.
- **Servings stepper (− 4 +)** that rescales ingredients right away; the API accepts `servings`.
- Ingredients in the reader's own units (the API converts).
- Steps numbered, in large text, readable at arm's length while cooking. Consider keeping the screen awake while a recipe is open.
- Actions:
  - **Save** (bookmark)
  - **Add to plan** (the main button)
  - **Make it yours** (fork), in an overflow menu so it doesn't compete with the main button

### Add to plan (bottom sheet)

- Pick a day (this week's days as chips, a calendar for later dates), a meal slot (breakfast, lunch, dinner, snack) and servings, defaulting to the household size.
- One tap to confirm. Adding the same meal twice does no harm: the API returns the meal that already exists.

### Plan

- **Week view:** the week as a vertical list of days, starting at today, which is highlighted. Each day shows its meals under small slot labels. Swipe or use arrows to change weeks.
- **Editing a meal:** tap it to change servings, move it or remove it. If the API answers `409` (someone else changed it), show "This meal was changed elsewhere. Here's the latest" and reload it. Don't show an error.
- **Overflow menu:** **Copy last week**, **Apply a template**, **Save week as template**. When the week already has meals, the API answers `409`; turn that into a clear choice: "Replace this week's 6 meals?" with **Cancel** / **Replace** (resend with `replace: true`).
- **Unavailable recipes:** meals whose recipe is no longer available (`unavailable: true`) appear greyed out with "No longer available" and a remove button.
- A **Make grocery list for this week** button.

### Groceries

- **Making a list:** show the preview first (`GET /grocery_lists/preview`), so the user sees it before saving. Then Save, with an optional name. If `unavailable_meals_count` is above zero, say e.g. "2 meals were left out because their recipes are no longer available".
- **Shopping mode** (the screen that matters most):
  - Sections in aisle order, big tap targets.
  - Tap an item to mark it **bought**: struck through and moved to the bottom of its section. A secondary action (swipe or long-press) marks it **"have it"**.
  - A progress line at the top: "12 of 30 left".
  - The recipes that need each item, in small text underneath.
- **Weak signal:** supermarkets often have poor reception. When an item is tapped, update the screen immediately, send the change in the background, and retry if it fails ("optimistic updates"). Never make the user wait for the server to cross something off. This is the biggest single improvement to how the app feels.

### Me

- Profile header: name, followers / following, private/public badge.
- Tabs underneath: **My recipes** and **Saved**.
- Badge for pending follow requests.
- **Settings:**
  - units
  - week start
  - household name and size
  - profile privacy
  - sign out
  - **Delete account**, explained honestly: "Your account is deactivated now and deleted after 30 days. Sign in again before then to keep it."

## 3. Visual design

Brand palette mapped to Material 3 color roles:

| Color | Role | Used for |
|---|---|---|
| `#1D5B79` | Primary | Main buttons, active tab, links |
| `#468B97` | Secondary | Chips, the servings stepper, less important actions |
| `#EF6262` | Tertiary | Delete, errors, the follow-request badge |
| `#F3AA60` | Quaternary | Highlights only ("Popular", today in the planner). **Never as text on white:** it fails contrast checks |

- **Dark mode:** support it from the start. It's much harder to add later.
- **Photos:** plenty of white space; let food photos carry the design.

## 4. Build order

Each milestone is something you can use:

1. **Skeleton and sign-in:**
   - Sign in, sign up and sign out, with the session token kept in the phone's secure storage.
   - The five tabs as placeholders.
   - Handling `401` (expired or revoked token) by returning to sign-in.
2. **Browse:** Home, Explore and Recipe detail, read-only. Teaches lists, pagination, loading states and navigation.
3. **Plan:** the week view and Add to plan.
4. **Groceries:** preview, saved lists and shopping mode with optimistic updates.
5. **Create and edit recipes:** forms, ingredient lines, photo upload through direct uploads.
6. **Social:** profiles, follows and requests.

Before milestone 1, work through the official Android Developers material:
- The **"Android Basics with Compose"** course.
- The **"Guide to app architecture"**.

Concepts worth learning first: Compose **state** and recomposition (the screen is redrawn from state), and **ViewModel** with `StateFlow` (where screen state lives so it survives rotation).

## 5. Android building blocks

The usual, well-documented choices for each need. All are standard; learn them as each milestone needs them, not all up front.

| Need | Building block | First needed |
|---|---|---|
| UI | Jetpack Compose with Material 3 (`NavigationBar`, `ModalBottomSheet`, `FloatingActionButton`, chips) | 1 |
| Screens and back navigation | Navigation Compose | 1 |
| Screen state | `ViewModel` + `StateFlow`, following the architecture guide (UI layer → data layer / repositories) | 1 |
| HTTP and JSON | Retrofit or Ktor, with kotlinx.serialization | 1 |
| Keeping the session token | DataStore, with the token encrypted using a key in the Android Keystore | 1 |
| Images | Coil | 2 |
| Infinite scroll | Paging 3 (maps well onto the API's `page` / `next_page` tokens) | 2 |
| Retrying grocery item changes when offline | WorkManager | 4 |
| Photo picking | The system Photo Picker | 5 |
| Dependency injection | Hilt, optional: worth adding once there are several repositories, not on day one | later |

**Running against the local Rails server:**
- **Android emulator:** reaches your computer's `localhost` as `10.0.2.2`.
- **Real phone:** needs your computer's network IP. Start Rails bound to all interfaces (its binding option) so the phone can reach it.
- **Plain HTTP:** Android blocks plain HTTP by default, so allow it for development builds only, via a network security config. Production must use HTTPS.

## 6. Notes for the iOS app later

- The screens, flows and states in this document carry over; the platform conventions change:
  - a tab bar instead of the navigation bar
  - sheets with "detents" instead of bottom sheets
  - a "+" in the navigation bar instead of a floating button
  - swipe actions on list rows
- SwiftUI is conceptually close to Compose (UI from state), and Swift is close to Kotlin, so the Android app's structure will translate.
- iOS development needs a Mac with Xcode.

## 7. Every screen needs

- A **loading** state (skeleton placeholders rather than spinners where possible).
- An **empty** state that tells the user what to do next.
- An **error** state with a retry, and a calm message when offline.
- Large enough tap targets (at least 48dp on Android) and support for the system font size.
