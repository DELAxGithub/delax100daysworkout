# Swift 6 Concurrency Violations

**Impact**: Future compatibility issues  
**Errors**: 8+ warnings becoming errors in Swift 6

## Actor Isolation Problems

### Protocol vs Implementation Mismatch
```swift
// Protocol expects nonisolated
protocol WeeklyPlanManaging {
    var analysisDataDescription: String { get }
}

// Implementation is MainActor isolated  
@MainActor class ProtocolBasedWeeklyPlanManager {
    var analysisDataDescription: String { ... } // ❌ Isolation mismatch
}
```

**Fix Options**:
1. Make protocol `@MainActor`
2. Make implementation nonisolated
3. Use `nonisolated` keyword

### WPRTestRunner Concurrency Issues
```swift
// Non-sendable capture
Task {
    analyzeWorkouts(context: modelContext)  // ❌ ModelContext not Sendable
}

// Concurrent mutation
testResults.append(...)  // ❌ Data race possible
```

**Fixes**:
- Use `@Sendable` closures properly
- Protect shared state with actors/locks
- Make captured types Sendable-compliant