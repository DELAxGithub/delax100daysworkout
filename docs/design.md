# Design: 100-Day Workout App

## 1. Architecture

We will adopt the **MVVM (Model-View-ViewModel)** architecture for this SwiftUI application. This pattern provides a clear separation of concerns, making the codebase scalable, testable, and maintainable.

-   **Model:** Represents the data and business logic. We will use **SwiftData** models to represent our app's data entities (e.g., `UserProfile`, `WorkoutLog`).
-   **View:** The UI layer of the application, built with SwiftUI. Views will be responsible for displaying data and capturing user input. They will be lightweight and reactive.
-   **ViewModel:** Acts as a bridge between the Model and the View. It will contain the presentation logic, format data for display, and handle user interactions passed from the View.

## 2. Data Persistence

-   **Framework:** We will use **SwiftData** for local on-device data persistence.
-   **Rationale:** SwiftData is Apple's modern, recommended framework for data persistence in SwiftUI applications. It integrates seamlessly with SwiftUI's reactive nature and simplifies data modeling and querying compared to Core Data or manual file management.
-   **Data Models (SwiftData `@Model`):**
    -   `UserProfile`: A singleton-like model to store the user's core profile and goals (current/goal weight, current/goal FTP, goal date).
    -   `DailyLog`: A model to store daily records, primarily the user's weight for that day.
    -   `WorkoutRecord`: A model to log completed workouts, containing details like type (Cycling, Strength, Flexibility), date, and potentially a summary string.

## 3. File & Project Structure

We will organize the Xcode project with a clear, feature-oriented structure.

```
Delax100DaysWorkout/
├── Delax100DaysWorkout.xcodeproj
├── Delax100DaysWorkout/
│   ├── Application/
│   │   ├── Delax100DaysWorkoutApp.swift   // App Entry Point
│   │   └── AppEnvironment.swift         // SwiftData container setup
│   │
│   ├── Features/
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   └── DashboardViewModel.swift
│   │   ├── Logging/
│   │   │   ├── LogEntryView.swift
│   │   │   └── LogEntryViewModel.swift
│   │   ├── ProgressView/
│   │   │   ├── ProgressChartView.swift
│   │   │   └── ProgressChartViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── SettingsViewModel.swift
│   │
│   ├── Components/                        // Reusable SwiftUI Views
│   │   ├── ProgressCircleView.swift
│   │   └── WorkoutCardView.swift
│   │
│   ├── Models/                            // SwiftData Models
│   │   ├── UserProfile.swift
│   │   ├── DailyLog.swift
│   │   └── WorkoutRecord.swift
│   │
│   └── Utilities/
│       └── DateManager.swift
│
└── Delax100DaysWorkout.entitlements
```

## 4. UI/UX Flow

-   The app will be centered around a `TabView` for main navigation.
-   **Tab 1: Dashboard:** The primary screen (`DashboardView`) showing the countdown, progress, and today's tasks.
-   **Tab 2: Progress:** A view (`ProgressChartView`) for visualizing historical data trends.
-   **Tab 3: Settings:** A form (`SettingsView`) for managing user profile and goals.
-   **Logging:** Workout and weight logging will be handled via a modal sheet (`LogEntryView`) presented from the Dashboard, ensuring quick and easy access.

## 5. Key Component Design

-   **`DashboardView.swift`:**
    -   Will use a `VStack` to lay out its components.
    -   Will display data from the `DashboardViewModel`.
    -   Will feature a prominent button to present the `LogEntryView` modal.

-   **`DashboardViewModel.swift`:**
    -   Will query SwiftData for the `UserProfile` and today's logs.
    -   Will calculate the current PWR.
    -   Will provide formatted strings and progress values (0.0 to 1.0) for the View.

-   **`ProgressChartView.swift`:**
    -   Will use the `Charts` framework.
    -   A `Picker` will allow the user to switch between viewing Weight, FTP, and PWR data.

-   **`LogEntryView.swift`:**
    -   Will use a `Form` to capture user input for different log types.
    -   Will communicate the new log data back to the relevant ViewModel to be saved in SwiftData.

## 6. Project Configuration

-   **Bundle Identifier:** `com.delax.Delax100DaysWorkout` (Example, can be adjusted)
-   **Team ID:** `Z88477N5ZU` (Based on `cloudkit` project)
-   **Target iOS Version:** 17.0 (to leverage the latest SwiftUI and SwiftData features).
