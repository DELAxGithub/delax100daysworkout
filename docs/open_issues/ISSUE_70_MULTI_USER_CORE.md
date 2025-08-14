# Issue #70: 多人数データ解析システム (Core)

**Priority**: Medium-High  
**Type**: Feature  
**Epic**: Academic Analysis System (Issue #58)  
**Estimated Effort**: 5-6 days

---

## 📋 Problem Statement

現行システムは個人トラッキング前提。複数被験者のデータを匿名化管理し、集団レベルの相関分析を可能にして学術的価値を向上。

---

## 🎯 Goals

### Primary Goals
- **匿名化被験者管理**: 個人特定不可能な被験者ID体系
- **集団相関分析**: 複数人データでの統計分析精度向上
- **研究グループ管理**: 研究プロジェクト単位でのデータ分離

### Success Metrics
- 被験者匿名化システム100%稼働
- 集団分析（n≥30）での統計的検出力≥0.8達成
- k-匿名性（k≥5）保証

---

## 🏗️ Technical Implementation

### 匿名化被験者管理
```swift
@Model
final class AnonymousSubject {
    var subjectId: String           // "SUB_001", "SUB_002" 形式
    var hashedOriginalId: String    // SHA-256ハッシュ
    var studyGroupId: String        // 研究グループID  
    var enrollmentDate: Date        // 登録日
    var demographicProfile: DemographicProfile? // 年齢層・性別など
    var consentLevel: ConsentLevel  // 同意レベル
    var isActive: Bool = true       // アクティブ状態
}

enum ConsentLevel: String, Codable {
    case basic = "Basic"           // 基本分析のみ
    case research = "Research"     // 学術研究利用
    case publication = "Publication" // 論文発表可能
}

@Model  
final class DemographicProfile {
    var ageGroup: AgeGroup         // enum: under20, 20s, 30s, 40s, 50plus
    var genderCategory: GenderCategory // enum: male, female, other, notSpecified
    var experienceLevel: ExperienceLevel // enum: beginner, intermediate, advanced
    var primarySport: SportCategory // enum: cycling, triathlon, running, other
}
```

### 研究プロジェクト管理
```swift
@Model
final class ResearchStudy {
    var studyId: String            // "STUDY_PWR_2025_Q3"
    var studyTitle: String         // 研究タイトル
    var principalInvestigator: String // 主任研究者（匿名化）
    var startDate: Date            // 開始日
    var endDate: Date?             // 終了日
    var subjects: [AnonymousSubject] // 被験者リスト
    var analysisObjectives: [String] // 分析目標
    var ethicsApprovalNumber: String? // 倫理審査番号
    var dataRetentionPeriod: Int   // データ保持期間（年）
}
```

### 集団相関分析エンジン
```swift
struct PopulationAnalysisEngine {
    func analyzePopulationCorrelations(studyId: String) async -> PopulationAnalysisResult {
        let subjects = await fetchStudySubjects(studyId)
        let allData = await aggregateSubjectData(subjects)
        
        return PopulationAnalysisResult(
            sampleSize: subjects.count,
            overallCorrelations: calculatePopulationCorrelations(allData),
            subgroupAnalysis: analyzeByDemographics(allData),
            individualVariability: calculateIndividualVariability(allData),
            statisticalPower: calculateStatisticalPower(subjects.count)
        )
    }
    
    func analyzeBySubgroups(_ data: [SubjectData]) -> [SubgroupAnalysis] {
        return [
            analyzeByAgeGroup(data),
            analyzeByGender(data), 
            analyzeByExperience(data),
            analyzeBySport(data)
        ]
    }
    
    func calculateStatisticalPower(sampleSize: Int, effectSize: Double = 0.3, alpha: Double = 0.05) -> Double {
        return PowerAnalysis.calculate(n: sampleSize, effectSize: effectSize, alpha: alpha)
    }
}
```

---

## ⚡ Implementation Plan

### Phase 1: 匿名化基盤構築 (2 days)
1. AnonymousSubject・ResearchStudyモデル実装
2. 匿名化ID生成・管理システム

### Phase 2: 集団分析エンジン (3 days)
1. PopulationAnalysisEngine実装
2. サブグループ分析・多水準分析
3. 統計的検出力計算

### Phase 3: 基本ダッシュボード (1 day)
1. 集団分析UI・可視化
2. 基本統計レポート生成

---

## 📊 Success Criteria

- [ ] 被験者匿名化システム稼働
- [ ] 集団分析エンジン実装完了
- [ ] サブグループ分析機能
- [ ] 基本統計レポート生成

*Created: 2025-08-13*  
*Status: Ready for Implementation*  
*Dependencies: Issue #58*