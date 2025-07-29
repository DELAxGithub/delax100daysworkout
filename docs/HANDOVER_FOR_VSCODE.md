# Handover Document: 100-Day Workout App (for VS Code Development)

## 1. Project Overview

**Objective:** To create a native iOS application that serves as a personal dashboard for managing and visualizing a 100-day intensive training program. The app will track progress in cycling (PWR), weight loss, and flexibility.

**Target User:** A single user (yourself) undertaking this specific challenge.

**Project Location:** `_Projects/delax100daysworkout/`

## 2. Development Plan & Specifications

This project follows a **spec-driven development** methodology. All planning documents are located in the `.gemini/specs/100-day-workout-app/` directory. Before starting implementation, please review them in the following order:

1.  **`requirements.md`**: Defines *what* the app needs to do from a user's perspective.
2.  **`design.md`**: Defines *how* the app will be built, including architecture and technology choices.
3.  **`implementation_plan.md`**: Provides a step-by-step guide for the entire implementation process.

## 3. Key Technologies & Architecture

-   **UI Framework:** SwiftUI
-   **Data Persistence:** SwiftData
-   **Architecture:** MVVM (Model-View-ViewModel)
-   **Target iOS:** 17.0
-   **Primary Language:** Swift

**Note:** While you will be using VS Code as your primary editor, **Xcode is still required** for the following critical tasks:

-   Initial project setup and configuration (`.xcodeproj` file).
-   Running the app on the iOS Simulator or a physical device.
-   Managing project capabilities (like CloudKit in the future).
-   Viewing and debugging the SwiftUI Preview.
-   Archiving and deploying the app.

## 4. Getting Started: Your First Steps

Your first task is to complete **Phase 1** of the `implementation_plan.md`.

1.  **Open Terminal:** Navigate to the project directory:
    ```bash
    cd "/Users/delax/Library/Mobile Documents/iCloud~md~obsidian/Documents/DELAXiobsidianicloud/_Projects/delax100daysworkout"
    ```

2.  **Create Xcode Project:**
    -   Open Xcode.
    -   Select "Create a new Xcode project".
    -   Choose the "App" template under the iOS tab.
    -   Name the project `Delax100DaysWorkout`.
    -   **Crucially, ensure you save it inside the `delax100daysworkout` directory we are already in.** This will create the `.xcodeproj` file alongside your `.gemini` folder.
    -   Set the Team to your developer account (`HIROSHI KODERA - Z88477N5ZU`).
    -   Set the Bundle Identifier (e.g., `com.delax.Delax100DaysWorkout`).
    -   Set the Minimum Deployment target to **iOS 17.0**.

3.  **Initialize Git:**
    -   In your terminal (still in the project root), run `git init`.
    -   Create a `.gitignore` file. You can start with a standard Swift template.
    -   Make your initial commit: `git add .` and `git commit -m "Initial project setup"`.

4.  **Open in VS Code & Implement Models:**
    -   Now, open the project folder in VS Code.
    -   Following the file structure in `design.md`, create the `Models` directory and the three SwiftData model files inside it:
        -   `UserProfile.swift`
        -   `DailyLog.swift`
        -   `WorkoutRecord.swift`
    -   Implement the code for these models as specified in the design document.

5.  **Configure SwiftData in Xcode:**
    -   Switch back to Xcode.
    -   Open the main app file (`Delax100DaysWorkoutApp.swift`).
    -   Add the `.modelContainer(for: ...)` modifier to set up the SwiftData stack as planned.

## 5. Next Steps

Once Phase 1 is complete, proceed to **Phase 2: Settings & User Profile** as detailed in the `implementation_plan.md`.

This document should provide all the context needed to begin. Good luck with the implementation!
