# Repository Guidelines

## Project Structure & Module Organization
- Source: `Delax100DaysWorkout/` with SwiftUI app entry `Delax100DaysWorkoutApp.swift`.
- Modules: `Features/` (screens), `Models/`, `Services/`, `Utils/`, `Application/` (app wiring), `Assets.xcassets/`.
- Xcode: `Delax100DaysWorkout.xcodeproj` at repo root.
- Docs: `docs/` (design, specs, progress). CI: `.github/workflows/`.
- Config: `.env.example`, `.env` (local only), `Config.plist`.

## Build, Test, and Development Commands
- Build (Simulator): `./build.sh` — cleans and builds the iOS scheme via `xcodebuild`.
- Open in Xcode: `open Delax100DaysWorkout.xcodeproj` — run/debug on a simulator/device.
- Watch mode (auto-fix scripts): `./watch-mode.sh` — requires `ANTHROPIC_API_KEY` and `auto-fix-config.yml`.
- Install pre-commit hook: `bash scripts/setup_git_hooks.sh` — enables secret scanning on commit.
- CI: PRs trigger “PR Code Check”; pushes run macOS auto-build/auto-fix.

## Coding Style & Naming Conventions
- Language: Swift (2-space indent, trailing commas avoided).
- Names: PascalCase types (`WorkoutRecord`), camelCase members (`weeklyPlanManager`). Views end with `View`, view models with `ViewModel`.
- Organization: group by feature under `Features/`; shared logic in `Services/` and `Models/`.
- Comments: use `// MARK:` to segment code. Prefer SwiftUI/SwiftData patterns already used.

## Testing Guidelines
- Functional checks live in Swift files (e.g., `WPRFunctionalTests.swift`). Suffix new helpers with `*Tests.swift`.
- Run tests from Xcode (Debug build) or call test helpers from a debug-only UI/action. Persist to SwiftData only when intentional.
- CI performs basic Swift syntax checks; ensure code passes locally before PR.

## Commit & Pull Request Guidelines
- Messages: short, imperative subjects; emoji allowed; prefixes like `fix:` occasionally used. Example: `feat: Add WeeklyReview chart`.
- PRs: clear description, link issues, include before/after screenshots for UI. Note simulator/device used.
- Checks: ensure pre-commit secret scan passes, CI is green, and no unrelated diffs.

## Security & Configuration Tips
- Do not commit secrets. Use `.env` (ignored) and `Config.plist` for non-sensitive config. Validate with `python3 scripts/check_secrets.py`.
- For GitHub Actions, store keys in repository Secrets. Locally, `export ANTHROPIC_API_KEY=...` before `./watch-mode.sh`.

