# Implementation Plan: 100-Day Workout App

This document breaks down the development process into sequential, manageable steps, based on the `requirements.md` and `design.md` files.

## Phase 1: Project Setup & Core Models (Day 1)

**Objective:** Create the foundational structure of the project and define the data layer.

1.  **Initialize Xcode Project:**
    -   Create a new SwiftUI App project in Xcode named `Delax100DaysWorkout`.
    -   Set the Bundle Identifier and Team ID as specified in the design document.
    -   Set the deployment target to iOS 17.0.

2.  **Setup Git Repository:**
    -   Initialize a Git repository in the project's root directory.
    -   Create a `.gitignore` file with standard Swift/Xcode ignores.
    -   Perform the initial commit.

3.  **Implement SwiftData Models:**
    -   Create `UserProfile.swift`, `DailyLog.swift`, and `WorkoutRecord.swift`.
    -   Define the schema for each model using the `@Model` macro as outlined in the design document.

4.  **Configure SwiftData Stack:**
    -   In `Delax100DaysWorkoutApp.swift`, set up the `.modelContainer()` for the defined models to inject it into the environment.

## Phase 2: Settings & User Profile (Day 2)

**Objective:** Build the functionality to input and edit user goals. This is crucial as the rest of the app depends on this data.

1.  **Create `SettingsViewModel.swift`:**
    -   Implement logic to fetch the `UserProfile` from SwiftData. If it doesn't exist, create a default one.
    -   Implement a `save()` method to persist any changes.

2.  **Create `SettingsView.swift`:**
    -   Build a `Form` with fields for all `UserProfile` properties (current/goal weight, current/goal FTP, goal date).
    -   Bind these fields to properties in the `SettingsViewModel`.
    -   Add a "Save" button in the navigation bar to trigger the save action.

3.  **Integrate into `TabView`:**
    -   Add the `SettingsView` as the third tab in the main `TabView`.

## Phase 3: Dashboard Implementation (Day 3-4)

**Objective:** Display the core motivational information to the user.

1.  **Create `DashboardViewModel.swift`:**
    -   Implement logic to fetch the `UserProfile`.
    -   Calculate the days remaining for the countdown.
    -   Calculate the current PWR.
    -   Calculate progress percentages for Weight, FTP, and PWR.

2.  **Create Reusable Components:**
    -   `ProgressCircleView.swift`: A view that takes a progress value (0.0-1.0) and displays a circular progress bar.
    -   `WorkoutCardView.swift`: A simple view to display information about a single scheduled workout.

3.  **Create `DashboardView.swift`:**
    -   Assemble the UI using the `DashboardViewModel`.
    -   Display the countdown timer prominently.
    -   Use the `ProgressCircleView` to show progress for the main goals.
    -   Lay out the "Today's Workout" section (static for now).

4.  **Integrate into `TabView`:**
    -   Set `DashboardView` as the first tab.

## Phase 4: Logging Functionality (Day 5-6)

**Objective:** Enable users to log their daily progress.

1.  **Create `LogEntryViewModel.swift`:**
    -   Implement methods to create and save new `DailyLog` and `WorkoutRecord` objects to SwiftData.

2.  **Create `LogEntryView.swift`:**
    -   Design a modal sheet with a `Picker` to select the log type (Weight, Strength, Cycling).
    -   Show the appropriate input fields based on the selection.
    -   Include "Save" and "Cancel" buttons.

3.  **Integrate with Dashboard:**
    -   Add a "+" button to the `DashboardView`.
    -   Wire it up to present the `LogEntryView` as a modal sheet.
    -   Ensure that after a log is saved, the Dashboard UI refreshes to reflect any new data (e.g., updated weight).

## Phase 5: Progress Visualization (Day 7)

**Objective:** Allow users to see their historical progress.

1.  **Create `ProgressChartViewModel.swift`:**
    -   Implement SwiftData queries to fetch all `DailyLog` records.
    -   Process and prepare the data for the `Charts` framework.

2.  **Create `ProgressChartView.swift`:**
    -   Use the `Charts` framework to create a line chart.
    -   Plot the user's weight over time.
    -   (Future iteration will add FTP/PWR charting).

3.  **Integrate into `TabView`:**
    -   Add the `ProgressChartView` as the second tab.

## Phase 6: Final Polish & Review (Day 8-9)

**Objective:** Refine the application and ensure all components work together seamlessly.

1.  **App Icon:** Create and add a simple, clean app icon.
2.  **UI Review:** Go through the entire app, polishing UI elements, and ensuring a consistent look and feel.
3.  **Code Cleanup:** Refactor any repetitive code and add comments where necessary.
4.  **Testing:** Manually test all user flows:
    -   Setting goals for the first time.
    -   Editing existing goals.
    -   Logging each type of workout.
    -   Verifying that new logs are reflected in the dashboard and progress charts.

## Phase 7: Build & Archive (Day 10)

**Objective:** Prepare the final build for deployment.

1.  **Final Build:** Perform a clean build of the project.
2.  **Archive:** Create an archive of the app in Xcode, preparing it for potential TestFlight distribution or on-device installation.
