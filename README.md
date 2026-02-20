# FPL-FDR-App
**Task Title:** Build a Premium SwiftUI Fantasy Premier League (FPL) FDR App

**Description & Requirements:**
You are an expert iOS Developer and UI/UX Designer. Please build a native iOS app using SwiftUI that tracks the Fantasy Premier League (FPL) Fixture Difficulty Rating (FDR). The app must be fully self-contained without needing external backend databases (other than the official FPL API) and must compile cleanly without strict developer entitlements so it can be sideloaded via TrollStore.

**1. Data & API Integration**
* Fetch live data from the official FPL endpoints:
    * Teams: `https://fantasy.premierleague.com/api/bootstrap-static/`
    * Fixtures: `https://fantasy.premierleague.com/api/fixtures/`
* Parse the JSON to extract team IDs, names, `short_name`, and fixture data (`team_h`, `team_a`, `event` for Gameweek, and `finished` status).
* Filter out any past Gameweeks where all matches are marked `finished: true`.
* Handle **Blank Gameweeks** (displaying a muted "BLANK" cell) and **Double Gameweeks** (stacking multiple fixture cells vertically within the same Gameweek column).

**2. State Management & Offline Capabilities**
* Use MVVM architecture (`FPLManager` as an `ObservableObject`).
* Implement a custom 1-7 difficulty rating system (Home and Away) for each team.
* Save these custom difficulty ratings, along with user filter preferences, to `UserDefaults` / `AppStorage` so the app remembers them offline and between sessions.

**3. Premium UI/UX Design**
* **Theme:** Enforce a strict, modern Dark Mode aesthetic utilizing deep blacks, dark grays, and glassmorphism (frosted glass) effects for menus and overlays.
* **Layout:**
    * A sticky left-hand column displaying the Team Logo and their calculated Average FDR score.
    * A horizontally scrollable right-hand grid displaying the upcoming Gameweeks.
* **Color Palette (Strict 1-7 Scale):**
    * Level 1: Deep Green (`Color(red: 0.0, green: 0.4, blue: 0.1)`)
    * Level 2: Light Green (`Color(red: 0.2, green: 0.8, blue: 0.3)`)
    * Level 3: Light Grey (`Color(red: 0.8, green: 0.8, blue: 0.8)`)
    * Level 4: Light Red (`Color(red: 1.0, green: 0.5, blue: 0.5)`)
    * Level 5: Standard Red (`Color(red: 0.9, green: 0.1, blue: 0.1)`)
    * Level 6: Dark Red (`Color(red: 0.6, green: 0.0, blue: 0.1)`)
    * Level 7: Extreme Dark Red (`Color(red: 0.3, green: 0.0, blue: 0.0)`)
* **Typography & Polish:** Use bold, legible fonts (`.system` with appropriate weights). Ensure text inside fixture boxes dynamically changes to black or white depending on the background color's brightness for perfect contrast.

**4. Settings & Filtering**
* Create a "Filters & Settings" view accessible via a toolbar icon.
* Include a segmented control to sort the main table by "Default API Order" or "Easiest Fixtures" (lowest Average FDR).
* Include standard steppers to set the Start and End Gameweek range. *Crucially, the Average FDR calculation must strictly respect this visible range.*
* Display a highly visual, tappable grid of team logos to easily toggle teams (Show/Hide) with a dimming effect for hidden teams.
* Provide a list view to manually override the Home and Away difficulty (1-7) for any team, using color-coded menus.

**5. Asset Management**
* Create a reusable `TeamLogoView`. It should attempt to load a local `.png` asset matching the team's lowercase `short_name` (e.g., `ars.png`). If the image is not found in the asset catalog, fall back gracefully to a polished text circle displaying the `short_name`.

Please generate the necessary Swift files, separate the UI into heavily optimized sub-views to prevent SwiftUI compiler timeouts, and ensure the code is robust, well-commented, and production-ready.