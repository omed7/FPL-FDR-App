# FPL-FDR-App
The Objective-C Master Prompt for Jules

Task Title: Build a Premium Objective-C UIKit FPL FDR App (Programmatic UI)

Description & Requirements:
You are an expert iOS Developer. Please build a native iOS app using Objective-C and UIKit. Do not use Swift or SwiftUI. The app must track the Fantasy Premier League (FPL) Fixture Difficulty Rating (FDR). It must be fully self-contained without needing external backend databases (other than the official FPL API) and must compile cleanly without strict developer entitlements or complex .xcodeproj files so it can be sideloaded.

1. Architecture & Frameworks

Language: Strictly Objective-C (.h and .m files).

UI Framework: UIKit. Do not use Storyboards or .xib files. All user interfaces, constraints (Auto Layout/NSLayoutConstraint), and views must be built 100% programmatically in code.

Architecture: Use standard MVC (Model-View-Controller) adapted for Objective-C.

2. Data & API Integration

Fetch live data from the official FPL endpoints using NSURLSession:

Teams: https://fantasy.premierleague.com/api/bootstrap-static/

Fixtures: https://fantasy.premierleague.com/api/fixtures/

Parse the JSON to extract team IDs, names, short_name, and fixture data (team_h, team_a, event for Gameweek, and finished status).

Filter out any past Gameweeks where all matches are marked finished: true.

Handle Blank Gameweeks (displaying a muted "BLANK" cell) and Double Gameweeks (stacking multiple fixture cells vertically).

3. State Management & Offline Capabilities

Implement a custom 1-7 difficulty rating system (Home and Away) for each team.

Save these custom difficulty ratings, along with user filter preferences, to NSUserDefaults so the app remembers them offline and between sessions.

4. Premium UI/UX Design

Theme: Enforce a strict, modern Dark Mode aesthetic utilizing deep blacks, dark grays, and UIVisualEffectView (frosted glass) effects for menus and overlays.

Layout:

A sticky left-hand column displaying the Team Logo and their calculated Average FDR score.

A horizontally scrollable right-hand grid displaying the upcoming Gameweeks (using UICollectionView).

Color Palette (Strict 1-7 Scale via UIColor):

Level 1: Deep Green (colorWithRed:0.0 green:0.4 blue:0.1 alpha:1.0)

Level 2: Light Green (colorWithRed:0.2 green:0.8 blue:0.3 alpha:1.0)

Level 3: Light Grey (colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0)

Level 4: Light Red (colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0)

Level 5: Standard Red (colorWithRed:0.9 green:0.1 blue:0.1 alpha:1.0)

Level 6: Dark Red (colorWithRed:0.6 green:0.0 blue:0.1 alpha:1.0)

Level 7: Extreme Dark Red (colorWithRed:0.3 green:0.0 blue:0.0 alpha:1.0)

5. Settings & Filtering

Create a "Filters & Settings" View Controller accessible via a navigation bar button.

Include a UISegmentedControl to sort the main table by "Default API Order" or "Easiest Fixtures".

Include standard UIStepper controls to set the Start and End Gameweek range. The Average FDR calculation must strictly respect this visible range.

Provide a UITableView to manually override the Home and Away difficulty (1-7) for any team.

6. Asset Management

Create a reusable image view component. It should attempt to load a local .png asset matching the team's lowercase short_name (e.g., [UIImage imageNamed:@"ars.png"]). If not found, fall back gracefully to a polished text circle displaying the short_name.