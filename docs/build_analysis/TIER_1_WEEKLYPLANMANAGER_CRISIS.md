# TIER 1: WeeklyPlanManager Integration Crisis

**File**: `SettingsViewModel.swift`  
**Errors**: 5 critical  
**Impact**: Complete integration failure

## Error Breakdown

### Error 1: Constructor Mismatch (Line 43)
```swift
self.weeklyPlanManager = WeeklyPlanManager(modelContext: modelContext)
//                                       ~~~~~~~~~~~~~~~^~~~~~~~~~~~~ 
// ERROR: extra argument 'modelContext' in call
```

**Fix**: Remove modelContext argument
```swift
self.weeklyPlanManager = WeeklyPlanManager()
```

### Errors 2-5: Missing Methods (Lines 105, 129, 133, 137)
```swift
await weeklyPlanManager.requestManualUpdate()           // ❌ Missing
weeklyPlanManager.analysisDataDescription               // ❌ Missing  
weeklyPlanManager.analysisResultDescription             // ❌ Missing
weeklyPlanManager.monthlyUsageDescription               // ❌ Missing
```

**Root Cause**: WeeklyPlanManaging protocol incomplete

**Fix**: Add to protocol:
```swift
protocol WeeklyPlanManaging {
    func requestManualUpdate() async
    var analysisDataDescription: String { get }
    var analysisResultDescription: String { get }
    var monthlyUsageDescription: String { get }
}
```