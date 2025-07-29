# Requirements: 100-Day Workout App

## 1. Core Purpose

The application will serve as a personal dashboard and logging tool for a user undertaking a 100-day intensive training program. It must track, manage, and visualize progress towards three distinct goals: cycling performance (PWR), weight loss, and flexibility.

## 2. User Stories

### Epic: Daily Motivation & Status Check

- **As a user, I want to** see a countdown to my 100-day goal date upon opening the app, **so that** I remain focused and aware of the timeline.
- **As a user, I want to** view my current Weight, FTP, and PWR on a main dashboard, **so that** I can instantly assess my current status against my goals.
- **As a user, I want to** see my progress towards my key goals visualized with progress bars, **so that** I get a quick, motivational overview of how far I've come.

### Epic: Workout Management & Execution

- **As a user, I want the app to** clearly display the scheduled workout(s) for the current day (Cycling, Strength, Flexibility), **so that** I know exactly what I need to do without consulting other documents.
- **As a user, I want to** be able to mark daily workouts as complete, **so that** I can feel a sense of accomplishment and track my adherence to the plan.

### Epic: Progress Logging

- **As a user, I want to** easily log my daily weight, **so that** I can track my weight loss progress over time.
- **As a user, I want to** log the details of my strength training sessions (e.g., exercise, weight, reps), **so that** I can monitor my strength gains.
- **As a user, I want to** log key metrics from my cycling sessions (e.g., duration, power), **so that** I have a record of my performance.

### Epic: Progress Visualization & Review

- **As a user, I want to** see a graph of my weight, FTP, and PWR over time, **so that** I can visually confirm my progress and identify trends.

### Epic: Goal Management

- **As a user, I want to** be able to set my initial and goal metrics (Weight, FTP) within the app, **so that** the application is personalized to my specific challenge.
- **As a user, I want to** be able to update my FTP value whenever I perform a new test, **so that** my PWR calculations and training zones remain accurate.

## 3. Functional Requirements

- **Dashboard:** The main screen must display:
    - Countdown timer.
    - Current vs. Goal metrics (Weight, FTP, PWR).
    - Progress bars for each primary goal.
    - Today's scheduled workouts.
- **Logging System:**
    - Must provide simple input forms for Weight, Strength, and Cycling logs.
    - Must store logs with a corresponding date.
- **Data Visualization:**
    - Must generate and display line charts for key metrics over the 100-day period.
- **Settings:**
    - Must allow the user to input and edit their profile and goal-related data.

## 4. Non-Functional Requirements

- **Platform:** iOS.
- **Data Storage:** All data will be stored locally on the device. CloudKit integration will be considered a future enhancement, not part of the MVP.
- **UI/UX:** The interface should be clean, intuitive, and motivational, requiring minimal taps to log data and view progress.
