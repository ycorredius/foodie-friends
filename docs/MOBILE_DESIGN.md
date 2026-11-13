# Mobile app design

The design for the mobile client: structure, screens, the experience on each, visual design and build order. It's a working draft: update it as decisions change. The app is being refocused on groceries and budgeting (see the mission in [ROADMAP.md](ROADMAP.md)), and it's called **Kettle & Coin**, with a cozy fantasy tavern feel. **Read [BRAND.md](BRAND.md) before writing any screen's wording:** the theme lives in the voice and a few brand nouns (the Hearthguild, the Innkeeper, the Innkeeper's picks, bill of fare), while tabs, buttons and money stay in plain words.

**Decided:**
- **React Native with Expo** (2026-11-13, replacing the earlier plan of native Kotlin, then Swift), written in TypeScript, in a separate repo. One codebase serves Android and iOS. **The MVP ships on Android only** (2026-11-13); iOS follows after it.
- **Built together with Claude Code** (changed 2026-11-13): Claude writes code for speed, and explains each concept as the project owner learns React Native. This document describes *what* to build and *why*; the code lives in the app's own repo.

## 1. App structure

**Bottom tabs** (standard on both platforms, 3–5 tabs). There are five:

| Tab | Purpose | API |
|---|---|---|
| **Home** | This week: budget, cost, savings and what's next | planned meals and costs (Phase 5) |
| **Explore** | Search and discover recipes; a **Following** view holds the feed | `GET /api/v1/recipes` with filters, `GET /api/v1/feed` |
| **Plan** | The week's meals | `meal_plans`, `planned_meals`, `plan_templates` |
| **Groceries** | Shopping lists | `grocery_lists` |
| **Me** | Your recipes, saved recipes, followers, settings | `me`, `saved_recipes`, `follow_requests` |

**Adding a recipe** is a floating "+" button on Explore and Me, not a tab: it's occasional, while browsing and planning are daily.

Screens opened on top of the tabs:
- Recipe detail
- Recipe editor
- Another user's profile
- Add to plan (bottom sheet)
- Settings

## 2. Screens

### Sign in / sign up

- Short and friendly. Sign-up asks for first name, last name, email and password only.
- After sign-up, a **short, skippable setup**: how many people you cook for, your weekly grocery budget, then diets and allergies, the day your week starts, and units (US or metric). Each one makes the app feel right from the start: the budget and savings appear right away, suggestions avoid what you can't eat, and planned meals default to the right servings.

### Home (this week)

The screen that carries the mission: what this week costs, and what it saves.
- **Budget:** the week's planned cost against the weekly budget, as a bar ("$64 of $90"). Over budget is shown calmly, with a way to fix it ("Swap for cheaper meals").
- **Savings:** "About $85 less than eating out this week", against the takeout price in settings.
- **Next meals:** today's and tomorrow's meals, each with its cost per serving.
- **Empty state:** a new user has no plan. In the Innkeeper's voice ("The hearth is cold..."), offer **the Innkeeper's picks** (starter weeks to copy) as the main button, with "Plan it myself" next to it. Once suggestions exist (Phase 8), **Suggest my week** joins them.
- Costs from estimates are marked as such ("est."), so users know they're approximate.

### Explore

- Search bar at the top (`q`).
- A **Following** view: recipes from people you follow (the feed), with infinite scroll and pull to refresh. A new user follows nobody, so its empty state offers "Find people to follow".
- **Shared weeks** (Phase 6): a Recipes / Weeks switch. Weeks shared by the community are "from the Hearthguild"; the starter weeks are "the Innkeeper's picks", shown first while the community is small. Week cards show the total, the household size it was planned for and cost per serving ("$62 · family of 4 · $2.20 a serving"), filterable by price and household size.

### Shared week (Phase 6)

- The week's meals by day, its total and cost per serving, and who shared it.
- **Re-costed for you:** the total shown is for *your* household size and *your* prices, with the original next to it ("$48 for your 3 people, $62 as shared").
- **Copy to my week:** choose the week to copy into. If it already has meals, ask "Replace this week's 6 meals?" as with templates.
- **Sharing your own week**, from the Plan overflow menu: a preview of exactly what others will see (meals, total, cost per serving; never your budget or spending), a visibility choice, then Share.
- Filter chips below it:
  - meal type (`meal_type`)
  - difficulty (`difficulty`)
  - time, e.g. "under 30 min" (`max_total_minutes`)
  - tags (`tags`)
- A Newest / Popular toggle (`sort`). Popular has a This week / Month / Year / All time picker (`period`). Cheapest and a cost filter come with Phase 5.
- **Recipe cards:** photo (or the placeholder), title, author, cost per serving and a save button. The same card is used everywhere, so the app feels consistent.
- Infinite scroll: fetch the next page with `next_page` as the user nears the bottom.

### Recipe detail

- Photo at the top, then title, author, times and **cost per serving** (with the total for the chosen servings).
- **Servings stepper (− 4 +)** that rescales ingredients and cost right away; the API accepts `servings`.
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

- **Week view:** the week as a vertical list of days, starting at today, which is highlighted. Each day shows its meals under small slot labels, with their costs. Swipe or use arrows to change weeks.
- **Budget bar** at the top: the week's planned cost against the budget, updated as meals change.
- **Suggest my week** (Phase 8): choose which days and slots to fill; the app proposes meals within the budget and your preferences. Review the proposal, swap any meal for another suggestion, then accept it.
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
  - **Prices:** the list's estimated checkout total at the top. After the MVP, an optional "what did you pay?" when checking an item off. Entered prices replace estimates for the household, so costs get more accurate the more the app is used. Keep it optional and quick: never block checking off on it.
- **Weak signal:** supermarkets often have poor reception. When an item is tapped, update the screen immediately, send the change in the background, and retry if it fails ("optimistic updates"). Never make the user wait for the server to cross something off. This is the biggest single improvement to how the app feels.

### Me

- Profile header: name, followers / following, private/public badge.
- Tabs underneath: **My recipes** and **Saved**.
- Badge for pending follow requests.
- **Settings:**
  - weekly budget and the eating-out price to compare against
  - diets, allergies and dislikes
  - units
  - week start
  - household name and size
  - profile privacy
  - sign out
  - **Delete account**, explained honestly: "Your account is deactivated now and deleted after 30 days. Sign in again before then to keep it."

## 3. Visual design

The **Sage & Slate** palette (chosen 2026-11-13; see [BRAND.md](BRAND.md)), as color roles. Define them once, as light and dark theme values, and use the roles in screens rather than hex codes:

| Role | Light | Dark | Used for |
|---|---|---|---|
| Primary (slate teal) | `#2F5D62` | `#7FB3B0` | Main buttons, active tab, links, the budget bar. Text on it: white in light mode, `#151B1B` in dark |
| Secondary (sage) | `#DBE8D6` | `#2C3D2C` | Chips, filters, the servings stepper. Text on it: `#2F4A2C` light, `#C4DCBF` dark |
| Highlight (wheat) | `#E9C46A` | `#E9C46A` | Highlights only ("Popular", today in the planner), with dark text on it. **Never as text:** too light to read on a light background |
| Savings (leaf) | `#3F7A4F` | `#93C49D` | Savings, "under budget" |
| Alert (terracotta) | `#B5523B` | `#E07A5F` | Delete, errors, the follow-request badge |
| Background | `#F4F5F1` | `#151B1B` | Screen background |
| Surface | `#FFFFFF` | `#1E2727` | Cards, panels, the tab bar |
| Text | `#1F2626` | `#E3EAE7` | Body text |
| Muted text | `#5F6A68` | `#9AAAA6` | Labels, dates, "est." |
| Divider / track | `#DFE4DF` | `#2E3A3A` | Row dividers, the empty part of the budget bar |

- **Contrast:** check each text and background pair against WCAG AA (4.5:1 for normal text) when the theme file is written; the values above were chosen to pass, but verify them.
- **Money:** show prices in dollars and cents, consistently formatted. Over budget doesn't use the alert color: the tone is encouraging, not alarming (see [BRAND.md](BRAND.md)).

- **Dark mode:** support it from the start. It's much harder to add later.
- **Photos:** plenty of white space; let food photos carry the design.

## 4. Build order

Each milestone is something you can use:

1. **Skeleton and sign-in:**
   - Sign in, sign up and sign out, with the session token kept in the phone's secure storage.
   - The five tabs as placeholders.
   - Handling `401` (expired or revoked token) by returning to sign-in.
2. **Browse:** Explore and Recipe detail, read-only. Teaches lists, pagination, loading states and navigation.
3. **Plan:** the week view and Add to plan.
4. **Groceries:** preview, saved lists, manual items and shopping mode with optimistic updates.
5. **Costs and Home:** costs on cards, recipes, the plan and lists; the budget bar; the Home screen. Built as the API's Phase 5 lands.
6. **Shared weeks:** browse, copy and share your own, with the API's Phase 6.
7. **Release:** the app name and icon, pointing at the production server, and an Android release (the API's Phase 7).

**Milestones 1–7 are the MVP** (see [ROADMAP.md](ROADMAP.md)). After it, in roughly this order:

8. **Suggestions:** preferences and Suggest my week, with the API's Phase 8.
9. **Social:** profiles, follows and requests, and the Following view.
10. **Create and edit recipes:** forms, ingredient lines, photo upload through direct uploads.
11. **iOS release.**

Until milestone 5, Home can show the week's planned meals without costs. Until milestone 8, its empty state offers starter weeks to copy instead of Suggest my week.

Before milestone 1, work through the official material, in this order:
- **react.dev "Learn"**: React itself (components, props, state, hooks). React Native is React with mobile building blocks instead of HTML.
- **React Native docs, "The Basics"**: core components (`View`, `Text`, `Image`, `FlatList`, `Pressable`) and styling.
- **The Expo tutorial**: creating a project, running it on your phone, and Expo Router.
- **TypeScript**: just enough to type props and API responses. The TypeScript handbook covers it; learn the rest as you go.

Concepts worth learning first:
- **The screen is drawn from state.** You don't change the screen directly; you change state, and React redraws. This is the core idea of React (and of Compose and SwiftUI).
- **Hooks** (`useState`, `useEffect`) and their rules.
- **Server state vs. screen state.** Data from the API (recipes, plans, lists) is a cached copy of the server's data and is best handled by a data-fetching library (section 5). Screen state (an open sheet, text being typed) stays in components.

## 5. Building blocks

The usual, well-documented choices for each need with Expo. Learn them as each milestone needs them, not all up front.

| Need | Building block | First needed |
|---|---|---|
| Project, tooling, running on the phone | Expo (with a development build once a library needs native code Expo Go doesn't include) | 1 |
| Screens, tabs and back navigation | Expo Router (file-based routes: the folder structure defines the screens and tabs) | 1 |
| HTTP and JSON | The built-in `fetch`, wrapped in one small API module that adds the `Authorization: Bearer` header and handles `401` | 1 |
| Server state: loading, caching, refetching | TanStack Query | 1 |
| Keeping the session token | `expo-secure-store` (Android Keystore / iOS Keychain underneath). Never AsyncStorage for the token | 1 |
| Images | `expo-image` (caching, placeholders) | 2 |
| Infinite scroll | `FlatList` with TanStack Query's infinite queries (they map onto the API's `page` / `next_page` tokens) | 2 |
| Bottom sheets | A bottom-sheet library such as `@gorhom/bottom-sheet`, or a modal route in Expo Router | 3 |
| Optimistic updates and retrying grocery changes offline | TanStack Query mutations (optimistic updates, paused while offline and resumed on reconnect) | 4 |
| Keeping the screen awake on a recipe | `expo-keep-awake` | 2 |
| Forms | Plain components and state at first; a form library such as React Hook Form if the recipe editor gets unwieldy | 5 |
| Photo picking | `expo-image-picker` | 5 |
| Global state | Not needed at first: TanStack Query holds server data, and a React context can hold the signed-in session | later |

**Styling:** React Native styles are plain objects, close to CSS with flexbox. Start with the built-in styles and a small theme file holding the color roles (section 3) for light and dark mode. A component library is optional; adopt one only if building the basics by hand gets slow.

**Running against the local Rails server:**
- **Real phone (Expo Go or a development build):** the phone and computer must be on the same Wi-Fi. The app uses your computer's network IP, and Rails must be started bound to all interfaces (its binding option) so the phone can reach it.
- **Android emulator:** reaches your computer's `localhost` as `10.0.2.2`.
- **API address:** keep it in an environment variable (Expo reads `EXPO_PUBLIC_*` variables), not in code, so development and production builds point at different servers.
- **Plain HTTP:** fine for development; production must use HTTPS.

## 6. Android and iOS differences

One codebase, but each platform has conventions worth respecting where they're cheap:
- **Back:** Android has a system back button or gesture; make sure it closes sheets and dialogs before leaving a screen. iOS uses a back button in the header and swipe-from-edge.
- **Adding a recipe:** a floating "+" button is the Android convention; on iOS a "+" in the header is more usual. Starting with the floating button on both is fine.
- **Sheets, tabs and lists:** bottom sheets, tab bars and swipe actions on list rows work on both, and the libraries above adapt their look per platform.
- **Building for iOS from Linux:** Expo Go on an iPhone works for development. App Store builds go through EAS Build (Expo's cloud build service), so no Mac is required; publishing needs an Apple Developer account.

## 7. Every screen needs

- A **loading** state (skeleton placeholders rather than spinners where possible).
- An **empty** state that tells the user what to do next.
- An **error** state with a retry, and a calm message when offline.
- Large enough tap targets (at least 48dp on Android, 44pt on iOS) and support for the system font size.
