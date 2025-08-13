import SwiftUI
import SwiftData

// MARK: - Search Configuration

struct SearchConfiguration {
    let placeholder: String
    let searchFields: [SearchField]
    let sortOptions: [SortOption]
    
    enum SearchField: CaseIterable {
        case value
        case date
        case notes
        case method
        
        var displayName: String {
            switch self {
            case .value: return "値"
            case .date: return "日付"
            case .notes: return "メモ"
            case .method: return "測定方法"
            }
        }
    }
    
    enum SortOption: CaseIterable {
        case dateNewest
        case dateOldest
        case valueHighest
        case valueLowest
        
        var displayName: String {
            switch self {
            case .dateNewest: return "日付（新しい順）"
            case .dateOldest: return "日付（古い順）"
            case .valueHighest: return "値（高い順）"
            case .valueLowest: return "値（低い順）"
            }
        }
        
        var icon: String {
            switch self {
            case .dateNewest: return "calendar.badge.minus"
            case .dateOldest: return "calendar.badge.plus"
            case .valueHighest: return "arrow.up.circle"
            case .valueLowest: return "arrow.down.circle"
            }
        }
    }
}

// MARK: - Unified Search Bar

struct UnifiedSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedSort: SearchConfiguration.SortOption
    @Binding var isSearchActive: Bool
    
    let configuration: SearchConfiguration
    let onClear: () -> Void
    
    @State private var showingSortOptions = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Search Input Row
                HStack(spacing: Spacing.sm.value) {
                    // Search Icon
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .font(.system(size: 16, weight: .medium))
                    
                    // Search TextField
                    TextField(configuration.placeholder, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                        .focused($isSearchFocused)
                        .onSubmit {
                            performSearch()
                        }
                    
                    // Clear Button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearchActive = false
                            onClear()
                            HapticManager.shared.trigger(.selection)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SemanticColor.secondaryText.color)
                                .font(.system(size: 16))
                        }
                    }
                    
                    // Sort Button
                    Button(action: {
                        showingSortOptions = true
                        HapticManager.shared.trigger(.selection)
                    }) {
                        HStack(spacing: Spacing.xs.value) {
                            Image(systemName: selectedSort.icon)
                            Text("並び替え")
                                .font(Typography.captionMedium.font)
                        }
                        .foregroundColor(SemanticColor.primaryAction.color)
                        .padding(.horizontal, Spacing.sm.value)
                        .padding(.vertical, Spacing.xs.value)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(SemanticColor.primaryAction.color.opacity(0.1))
                        )
                    }
                }
                .frame(minHeight: 44)
                .padding(.horizontal, Spacing.sm.value)
                .padding(.vertical, Spacing.xs.value)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColor.surfaceBackground.color)
                        .stroke(
                            isSearchFocused ? SemanticColor.primaryAction.color : SemanticColor.primaryBorder.color,
                            lineWidth: isSearchFocused ? 2 : 1
                        )
                )
                
                // Active Search Indicator
                if isSearchActive && !searchText.isEmpty {
                    HStack {
                        Text("検索中: \"\(searchText)\"")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.primaryAction.color)
                        
                        Spacer()
                        
                        Text("並び順: \(selectedSort.displayName)")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                }
            }
            .padding(Spacing.md.value)
        }
        .confirmationDialog("並び替え", isPresented: $showingSortOptions) {
            ForEach(SearchConfiguration.SortOption.allCases, id: \.self) { option in
                Button(option.displayName) {
                    selectedSort = option
                    HapticManager.shared.trigger(.selection)
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("検索とフィルター")
    }
    
    private func performSearch() {
        isSearchActive = !searchText.isEmpty
        isSearchFocused = false
        if isSearchActive {
            HapticManager.shared.trigger(.notification(.success))
        }
    }
}

// MARK: - Search Configurations

extension SearchConfiguration {
    static let ftpHistory = SearchConfiguration(
        placeholder: "FTP値、日付、メモで検索...",
        searchFields: [.value, .date, .notes, .method],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let metricsHistory = SearchConfiguration(
        placeholder: "体重、心拍数、日付で検索...",
        searchFields: [.value, .date, .method],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let workoutHistory = SearchConfiguration(
        placeholder: "種目、時間、強度、メモで検索...",
        searchFields: [.value, .date, .notes, .method],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let dailyLogHistory = SearchConfiguration(
        placeholder: "体重、タンパク質、水分量で検索...",
        searchFields: [.value, .date, .notes],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let achievementHistory = SearchConfiguration(
        placeholder: "達成内容、ポイント、日付で検索...",
        searchFields: [.value, .date, .notes],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let weeklyReportHistory = SearchConfiguration(
        placeholder: "週番号、完了率、ワークアウト数で検索...",
        searchFields: [.value, .date, .notes],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
    
    static let trainingSavingsHistory = SearchConfiguration(
        placeholder: "節約額、種類、日付で検索...",
        searchFields: [.value, .date, .notes],
        sortOptions: SearchConfiguration.SortOption.allCases
    )
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg.value) {
        UnifiedSearchBar(
            searchText: .constant(""),
            selectedSort: .constant(.dateNewest),
            isSearchActive: .constant(false),
            configuration: .ftpHistory,
            onClear: {}
        )
        
        UnifiedSearchBar(
            searchText: .constant("250"),
            selectedSort: .constant(.valueHighest),
            isSearchActive: .constant(true),
            configuration: .ftpHistory,
            onClear: {}
        )
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}