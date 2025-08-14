import SwiftUI
import SwiftData
import Foundation

struct AdvancedFilteringEngine<T: PersistentModel> {
    
    enum FilterCondition: Equatable {
        case text(property: String, operation: TextOperation, value: String)
        case number(property: String, operation: NumberOperation, value: Double)
        case date(property: String, operation: DateOperation, value: Date)
        case bool(property: String, value: Bool)
        case enumeration(property: String, value: String)
        case isNull(property: String)
        case isNotNull(property: String)
        
        enum TextOperation: String, CaseIterable {
            case contains = "contains"
            case startsWith = "starts with"
            case endsWith = "ends with"
            case equals = "equals"
            case notEquals = "not equals"
            
            var displayName: String { rawValue }
        }
        
        enum NumberOperation: String, CaseIterable {
            case equals = "="
            case notEquals = "≠"
            case greaterThan = ">"
            case greaterThanOrEqual = "≥"
            case lessThan = "<"
            case lessThanOrEqual = "≤"
            case between = "between"
            
            var displayName: String { rawValue }
        }
        
        enum DateOperation: String, CaseIterable {
            case equals = "on"
            case before = "before"
            case after = "after"
            case between = "between"
            case today = "today"
            case thisWeek = "this week"
            case thisMonth = "this month"
            case thisYear = "this year"
            
            var displayName: String { rawValue }
        }
    }
    
    enum LogicalOperator: String, CaseIterable, Equatable {
        case and = "AND"
        case or = "OR"
        
        var displayName: String { rawValue }
    }
    
    struct FilterGroup: Equatable {
        var conditions: [FilterCondition] = []
        var logicalOperator: LogicalOperator = .and
        var nestedGroups: [FilterGroup] = []
        
        var isEmpty: Bool {
            conditions.isEmpty && nestedGroups.allSatisfy(\.isEmpty)
        }
    }
    
    struct FilterPreset {
        let id = UUID()
        let name: String
        let description: String
        let filterGroup: FilterGroup
        let createdAt: Date
        
        init(name: String, description: String = "", filterGroup: FilterGroup) {
            self.name = name
            self.description = description
            self.filterGroup = filterGroup
            self.createdAt = Date()
        }
    }
    
    private let modelType: T.Type
    private let availableProperties: [PropertyAnalyzer.PropertyInfo]
    
    init(modelType: T.Type) {
        self.modelType = modelType
        self.availableProperties = PropertyAnalyzer.analyzeModel(modelType)
    }
    
    func buildPredicate(from filterGroup: FilterGroup) -> Predicate<T>? {
        guard !filterGroup.isEmpty else { return nil }
        
        let conditionPredicates = filterGroup.conditions.compactMap { condition in
            buildPredicate(from: condition)
        }
        
        let nestedPredicates = filterGroup.nestedGroups.compactMap { group in
            buildPredicate(from: group)
        }
        
        let allPredicates = conditionPredicates + nestedPredicates
        
        guard !allPredicates.isEmpty else { return nil }
        
        if allPredicates.count == 1 {
            return allPredicates[0]
        }
        
        switch filterGroup.logicalOperator {
        case .and:
            return combinePredicatesWithAnd(allPredicates)
        case .or:
            return combinePredicatesWithOr(allPredicates)
        }
    }
    
    private func buildPredicate(from condition: FilterCondition) -> Predicate<T>? {
        switch condition {
        case .text(let property, let operation, let value):
            return buildTextPredicate(property: property, operation: operation, value: value)
            
        case .number(let property, let operation, let value):
            return buildNumberPredicate(property: property, operation: operation, value: value)
            
        case .date(let property, let operation, let value):
            return buildDatePredicate(property: property, operation: operation, value: value)
            
        case .bool(let property, let value):
            return buildBoolPredicate(property: property, value: value)
            
        case .enumeration(let property, let value):
            return buildEnumPredicate(property: property, value: value)
            
        case .isNull(let property):
            return buildNullPredicate(property: property, isNull: true)
            
        case .isNotNull(let property):
            return buildNullPredicate(property: property, isNull: false)
        }
    }
    
    private func buildTextPredicate(
        property: String,
        operation: FilterCondition.TextOperation,
        value: String
    ) -> Predicate<T>? {
        // Note: This is a simplified implementation
        // In a real scenario, you would need to use Swift's predicate system
        // which requires compile-time property access
        return nil
    }
    
    private func buildNumberPredicate(
        property: String,
        operation: FilterCondition.NumberOperation,
        value: Double
    ) -> Predicate<T>? {
        // Simplified implementation
        return nil
    }
    
    private func buildDatePredicate(
        property: String,
        operation: FilterCondition.DateOperation,
        value: Date
    ) -> Predicate<T>? {
        // Simplified implementation
        return nil
    }
    
    private func buildBoolPredicate(property: String, value: Bool) -> Predicate<T>? {
        // Simplified implementation
        return nil
    }
    
    private func buildEnumPredicate(property: String, value: Any) -> Predicate<T>? {
        // Simplified implementation
        return nil
    }
    
    private func buildNullPredicate(property: String, isNull: Bool) -> Predicate<T>? {
        // Simplified implementation
        return nil
    }
    
    private func combinePredicatesWithAnd(_ predicates: [Predicate<T>]) -> Predicate<T>? {
        guard !predicates.isEmpty else { return nil }
        
        return predicates.reduce(predicates[0]) { result, predicate in
            #Predicate<T> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }
    }
    
    private func combinePredicatesWithOr(_ predicates: [Predicate<T>]) -> Predicate<T>? {
        guard !predicates.isEmpty else { return nil }
        
        return predicates.reduce(predicates[0]) { result, predicate in
            #Predicate<T> { item in
                result.evaluate(item) || predicate.evaluate(item)
            }
        }
    }
    
    func getAvailableProperties() -> [PropertyAnalyzer.PropertyInfo] {
        return availableProperties.filter { property in
            // Filter out relationship properties for now
            if case .relationship = property.type {
                return false
            }
            return true
        }
    }
    
    func getSupportedOperations(for propertyType: PropertyAnalyzer.PropertyType) -> [Any] {
        switch propertyType {
        case .string:
            return FilterCondition.TextOperation.allCases
        case .int, .double:
            return FilterCondition.NumberOperation.allCases
        case .date:
            return FilterCondition.DateOperation.allCases
        case .bool:
            return [true, false]
        case .enumeration:
            return ["equals", "not equals"]
        default:
            return []
        }
    }
}

extension AdvancedFilteringEngine {
    static func createWorkoutRecordPresets() -> [FilterPreset] {
        return [
            FilterPreset(
                name: "Today's Workouts",
                description: "Workouts scheduled for today",
                filterGroup: FilterGroup(
                    conditions: [
                        .date(property: "date", operation: .today, value: Date())
                    ]
                )
            ),
            FilterPreset(
                name: "Completed This Week",
                description: "All completed workouts from this week",
                filterGroup: FilterGroup(
                    conditions: [
                        .date(property: "date", operation: .thisWeek, value: Date()),
                        .bool(property: "isCompleted", value: true)
                    ],
                    logicalOperator: .and
                )
            ),
            FilterPreset(
                name: "Pending Cycling",
                description: "Incomplete cycling workouts",
                filterGroup: FilterGroup(
                    conditions: [
                        .enumeration(property: "workoutType", value: WorkoutType.cycling),
                        .bool(property: "isCompleted", value: false)
                    ],
                    logicalOperator: .and
                )
            ),
            FilterPreset(
                name: "This Month's Strength",
                description: "All strength training this month",
                filterGroup: FilterGroup(
                    conditions: [
                        .date(property: "date", operation: .thisMonth, value: Date()),
                        .enumeration(property: "workoutType", value: WorkoutType.strength)
                    ],
                    logicalOperator: .and
                )
            )
        ]
    }
    
    static func createUserProfilePresets() -> [FilterPreset] {
        return [
            FilterPreset(
                name: "Active Goals",
                description: "Profiles with future goal dates",
                filterGroup: FilterGroup(
                    conditions: [
                        .date(property: "goalDate", operation: .after, value: Date())
                    ]
                )
            ),
            FilterPreset(
                name: "Weight Loss Goals",
                description: "Profiles targeting weight loss",
                filterGroup: FilterGroup(
                    conditions: [
                        // Note: This would need proper predicate building
                        // .custom(property: "goalWeightKg < startWeightKg")
                    ]
                )
            )
        ]
    }
}