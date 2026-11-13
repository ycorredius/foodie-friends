# Mobile app design

The design for the Foodie Friends mobile client: structure, screens, the experience on each, visual design and build order. It's a working draft: update it as decisions change.

**Decided:**
- **React Native with Expo** (2026-11-13, replacing the earlier plan of native Kotlin, then Swift), written in TypeScript, in a separate repo. One codebase serves Android and iOS. Testing starts on an Android phone.
- **Built by hand** by the project owner. This document describes *what* to build and *why*, not how to code it.

## 1. App structure

**Bottom tabs** (standard on both platforms, 3–5 tabs). There are five:

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

Brand palette as color roles. Define them once, as light and dark theme values, and use the roles in screens rather than hex codes:

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
