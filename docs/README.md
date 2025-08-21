# Delax 100 Days Workout

Simple fitness tracking app with 3 core workout types.

## Quick Start
```bash
# Build the app
xcodebuild -project Delax100DaysWorkout.xcodeproj -scheme Delax100DaysWorkout build

# Or use available device
xcodebuild -project Delax100DaysWorkout.xcodeproj -scheme Delax100DaysWorkout -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Core Features
- **Cycling**: Duration, intensity, power tracking
- **Strength**: Sets, reps, weight tracking  
- **Flexibility**: Duration, measurements tracking

## Architecture
- **Language**: Swift 5.9
- **UI**: SwiftUI 
- **Data**: SwiftData with JSON storage
- **Min iOS**: 18.5

## Data Model
- Simplified JSON-based storage via SwiftData
- `WorkoutRecord` with type-specific JSON fields
- `@Transient` computed properties for type safety

## Recent Changes
- ✅ Migrated from complex relationships to JSON storage
- ✅ Implemented QuickRecordView for simplified input
- ✅ Eliminated all build errors - **BUILD SUCCEEDED**
- ✅ Focused on 3 core workout types (removed complexity)

## Documentation
See CLAUDE.md for development commands and architecture details.