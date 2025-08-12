# Data Migration Strategy

## Overview
This document outlines the data migration strategy for implementing the new validation and integrity system in the Delax100DaysWorkout app.

## Migration Phases

### Phase 1: Validation Implementation (Completed)
- ✅ Created `ModelValidation` protocol for consistent validation
- ✅ Added validation extensions to all core models:
  - UserProfile
  - DailyLog
  - WorkoutRecord
  - StrengthDetail
  - FlexibilityDetail
  - FTPHistory
  - DailyMetric (enhanced existing validation)
  - CyclingDetail (enhanced existing validation)
- ✅ Created `DataIntegrityManager` service for centralized validation

### Phase 2: Data Cleanup (To be implemented)
1. **Duplicate Detection and Merge**
   - Run `DataIntegrityManager.repairDuplicateDailyMetrics()` on first launch
   - Merge duplicate entries based on date and priority (Apple Health > Manual > Calculated)

2. **Invalid Data Correction**
   - Identify records with validation errors
   - Apply automatic corrections where safe:
     - Negative values → 0
     - Out-of-range dates → nearest valid date
     - Missing required fields → sensible defaults

3. **Orphaned Records Cleanup**
   - Delete WorkoutRecords without corresponding detail records
   - Remove detail records without parent WorkoutRecords

### Phase 3: Schema Updates (Future)
1. **Add Validation Constraints to SwiftData Models**
   ```swift
   @Model
   final class UserProfile {
       @Attribute(.unique) var id: UUID
       @Attribute(.validation(.range(30...200))) var startWeightKg: Double
       // etc.
   }
   ```

2. **Add Indexes for Better Performance**
   - Index on date fields for faster queries
   - Composite indexes for common query patterns

### Phase 4: Ongoing Maintenance
1. **Pre-save Validation**
   - All models validate before saving
   - User receives immediate feedback on invalid data

2. **Regular Integrity Checks**
   - Weekly background validation
   - Monthly full data integrity scan
   - Automatic repair of common issues

## Migration Code Implementation

### On App Launch
```swift
func performMigrationIfNeeded() async {
    let userDefaults = UserDefaults.standard
    let migrationVersion = userDefaults.integer(forKey: "DataMigrationVersion")
    
    if migrationVersion < 1 {
        // Phase 1: Clean up duplicates
        await integrityManager.repairDuplicateDailyMetrics()
        userDefaults.set(1, forKey: "DataMigrationVersion")
    }
    
    if migrationVersion < 2 {
        // Phase 2: Validate all existing data
        await integrityManager.performFullValidation()
        userDefaults.set(2, forKey: "DataMigrationVersion")
    }
}
```

### Before Saving Any Model
```swift
func saveWorkoutRecord(_ record: WorkoutRecord) throws {
    try integrityManager.validateBeforeSave(record)
    try modelContext.save()
}
```

## Rollback Strategy

If migration fails:
1. Keep original data intact (never delete without backup)
2. Log all migration errors for debugging
3. Allow app to function with validation warnings
4. Provide manual correction UI for users

## Testing Strategy

1. **Unit Tests**
   - Test each validation rule individually
   - Test edge cases and boundary conditions
   - Test migration logic with sample data

2. **Integration Tests**
   - Test full validation flow
   - Test data integrity checks
   - Test migration on real-world data samples

3. **User Acceptance Testing**
   - Beta test with subset of users
   - Monitor validation error rates
   - Gather feedback on validation rules

## Performance Considerations

1. **Batch Processing**
   - Process validations in chunks of 100 records
   - Use background queues for large datasets

2. **Caching**
   - Cache validation results for unchanged records
   - Invalidate cache on model updates

3. **Progressive Enhancement**
   - Start with basic validation
   - Add complex rules gradually
   - Monitor performance impact

## Error Handling

1. **Validation Errors**
   - Show user-friendly error messages
   - Provide suggestions for fixing errors
   - Allow saving with warnings (not errors)

2. **Migration Errors**
   - Log detailed error information
   - Continue app operation (degraded mode)
   - Report errors to crash analytics

## Success Metrics

- < 1% validation error rate on new data
- < 5% validation warnings on existing data
- Zero data loss during migration
- < 100ms validation time for single record
- < 5s for full database validation (1000 records)