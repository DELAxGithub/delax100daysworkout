#!/usr/bin/env python3

import argparse
import json
import os
import sys
from github import Github
import tiktoken
from cost_tracker import CostTracker

class CostEstimator:
    def __init__(self, github_token):
        self.github = Github(github_token)
        # Claude Opus 4 pricing (per million tokens)
        self.pricing = {
            "claude-opus-4-20250514": {
                "input": 15.0,
                "output": 75.0
            },
            "claude-sonnet-4-20250514": {
                "input": 3.0,
                "output": 15.0
            }
        }
        # Use cl100k_base encoding as approximation
        self.encoder = tiktoken.get_encoding("cl100k_base")
        
    def estimate_tokens(self, text):
        """Estimate token count for text"""
        return len(self.encoder.encode(text))
        
    def estimate_issue_cost(self, repo_name, issue_number, model="claude-opus-4-20250514"):
        """Estimate cost for processing an issue"""
        repo = self.github.get_repo(repo_name)
        issue = repo.get_issue(issue_number)
        
        # Check for duplicate issues
        duplicate = self._check_duplicate(repo, issue)
        if duplicate:
            return {
                "is_duplicate": True,
                "original_issue": duplicate,
                "estimated_cost": 0
            }
        
        # Estimate tokens for analysis phase
        analysis_prompt = self._build_analysis_prompt(issue)
        analysis_input_tokens = self.estimate_tokens(analysis_prompt)
        analysis_output_tokens = 500  # Estimated JSON response
        
        # Estimate tokens for fix generation phase
        # Assume we'll analyze 3 files with ~500 lines each
        fix_prompt_base = 1000  # Base prompt
        file_content_tokens = 3 * 2000  # 3 files * ~2000 tokens each
        fix_input_tokens = fix_prompt_base + file_content_tokens
        fix_output_tokens = 1000  # Estimated fix code
        
        # Calculate total tokens
        total_input_tokens = analysis_input_tokens + fix_input_tokens
        total_output_tokens = analysis_output_tokens + fix_output_tokens
        
        # Calculate cost
        pricing = self.pricing[model]
        input_cost = (total_input_tokens / 1_000_000) * pricing["input"]
        output_cost = (total_output_tokens / 1_000_000) * pricing["output"]
        total_cost = input_cost + output_cost
        
        return {
            "is_duplicate": False,
            "model": model,
            "estimated_tokens": {
                "analysis": {
                    "input": analysis_input_tokens,
                    "output": analysis_output_tokens
                },
                "fix_generation": {
                    "input": fix_input_tokens,
                    "output": fix_output_tokens
                },
                "total": {
                    "input": total_input_tokens,
                    "output": total_output_tokens,
                    "combined": total_input_tokens + total_output_tokens
                }
            },
            "estimated_cost": {
                "input": round(input_cost, 4),
                "output": round(output_cost, 4),
                "total": round(total_cost, 4)
            },
            "cost_breakdown": {
                "analysis": round((analysis_input_tokens + analysis_output_tokens) / 1_000_000 * 
                                ((pricing["input"] + pricing["output"]) / 2), 4),
                "fix_generation": round((fix_input_tokens + fix_output_tokens) / 1_000_000 * 
                                      ((pricing["input"] + pricing["output"]) / 2), 4)
            }
        }
        
    def _check_duplicate(self, repo, issue):
        """Check if this is a duplicate issue"""
        # Get recent issues with same title
        all_issues = repo.get_issues(state='all')
        for other_issue in all_issues:
            if (other_issue.number != issue.number and 
                other_issue.title == issue.title and
                (issue.created_at - other_issue.created_at).total_seconds() < 3600):  # Within 1 hour
                return other_issue.number
        return None
        
    def _build_analysis_prompt(self, issue):
        """Build the analysis prompt to estimate tokens"""
        prompt = f"""
あなたはiOSアプリのバグ分析エキスパートです。
以下のバグ報告を分析して、自動修正が可能かどうか判定してください。

## バグ報告内容
タイトル: {issue.title}
本文: {issue.body or ''}

## ラベル
{', '.join([label.name for label in issue.labels])}

以下の形式でJSON形式で分析結果を返してください：
{{
    "can_auto_fix": true/false,
    "confidence": 0-100,
    "bug_type": "カテゴリ",
    "affected_files": ["推測されるファイルパス"],
    "root_cause": "推測される原因",
    "fix_strategy": "修正方針",
    "risk_level": "low/medium/high",
    "reason": "自動修正できない理由（can_auto_fix=falseの場合）"
}}
"""
        return prompt
        
    def post_estimate_comment(self, repo_name, issue_number, estimate, model="claude-opus-4-20250514", cost_check=None):
        """Post cost estimate as issue comment"""
        repo = self.github.get_repo(repo_name)
        issue = repo.get_issue(issue_number)
        
        if estimate["is_duplicate"]:
            comment = f"""🤖 **重複Issueを検出しました**

このIssueは #{estimate['original_issue']} と重複しています。
自動修正をスキップします。"""
        elif cost_check and not cost_check['can_afford']:
            # Cost limit exceeded
            comment = f"""🤖 **⚠️ 月間コスト制限に達しています**

**推定コスト**: ${estimate['estimated_cost']['total']:.3f}
**現在の使用量**: ${cost_check['current_usage']:.3f} / $5.00 ({cost_check['usage_percentage']:.1f}%)
**予想合計**: ${cost_check['projected_total']:.3f}

🔴 **自動修正を停止しました**: 月間$5制限を超過するため、このIssueの自動修正は実行できません。

**対処法**:
- 月初まで待つ（自動リセット）
- 手動で修正を行う
- 緊急時は開発者にお問い合わせください

**コスト詳細**:
  - 入力コスト: ${estimate['estimated_cost']['input']:.3f}
  - 出力コスト: ${estimate['estimated_cost']['output']:.3f}
  - 残額: ${cost_check['remaining']:.3f}"""
        else:
            model_name = "Claude Opus 4" if "opus" in model else "Claude Sonnet 4"
            
            # Add cost status
            cost_status = ""
            if cost_check:
                status_emoji = "🟡" if not cost_check['within_warning'] else "🟢"
                cost_status = f"""
**💰 月間コスト制限**: ${cost_check['current_usage']:.3f} / $5.00 ({cost_check['usage_percentage']:.1f}%)
{status_emoji} **予想合計**: ${cost_check['projected_total']:.3f} (残額: ${cost_check['remaining']:.3f})
"""
            
            warning_text = ""
            if cost_check and not cost_check['within_warning']:
                warning_text = "\n⚠️ **警告**: この実行により$4制限に近づきます。"
            
            comment = f"""🤖 **自動修正のコスト見積もり**

**モデル**: {model_name}
**推定トークン数**: {estimate['estimated_tokens']['total']['combined']:,} 
  - 入力: {estimate['estimated_tokens']['total']['input']:,}
  - 出力: {estimate['estimated_tokens']['total']['output']:,}

**推定コスト**: ${estimate['estimated_cost']['total']:.3f}
  - 入力コスト: ${estimate['estimated_cost']['input']:.3f}
  - 出力コスト: ${estimate['estimated_cost']['output']:.3f}

**処理内訳**:
  - バグ分析: ${estimate['cost_breakdown']['analysis']:.3f}
  - 修正生成: ${estimate['cost_breakdown']['fix_generation']:.3f}
{cost_status}{warning_text}

---

承認する場合は、このコメントに 👍 リアクションをつけてください。
24時間以内に承認がない場合、自動的にキャンセルされます。

⚠️ **注意**: これは推定値です。実際のコストは内容により変動する可能性があります。"""
        
        comment_obj = issue.create_comment(comment)
        return comment_obj.id

def main():
    parser = argparse.ArgumentParser(description='Estimate cost for auto-fix')
    parser.add_argument('--issue-number', type=int, required=True)
    parser.add_argument('--repo', type=str, required=True)
    parser.add_argument('--model', type=str, default='claude-opus-4-20250514',
                        choices=['claude-opus-4-20250514', 'claude-sonnet-4-20250514'])
    
    args = parser.parse_args()
    
    # 環境変数から認証情報を取得
    github_token = os.environ.get('GITHUB_TOKEN')
    
    if not github_token:
        print("Error: GITHUB_TOKEN must be set")
        sys.exit(1)
        
    estimator = CostEstimator(github_token)
    cost_tracker = CostTracker(github_token, args.repo)
    
    try:
        # コスト見積もり
        estimate = estimator.estimate_issue_cost(args.repo, args.issue_number, args.model)
        
        # コスト制限チェック
        cost_check = None
        if not estimate.get("is_duplicate", False):
            cost_check = cost_tracker.can_afford(estimate['estimated_cost']['total'])
        
        # コメント投稿
        comment_id = estimator.post_estimate_comment(args.repo, args.issue_number, estimate, args.model, cost_check)
        
        # GitHub Actionsの出力として設定
        github_output = os.environ.get('GITHUB_OUTPUT')
        if github_output:
            with open(github_output, 'a') as f:
                f.write(f"is_duplicate={str(estimate.get('is_duplicate', False)).lower()}\n")
                f.write(f"estimated_cost={estimate.get('estimated_cost', {}).get('total', 0)}\n")
                f.write(f"comment_id={comment_id}\n")
                f.write(f"estimate_json={json.dumps(estimate)}\n")
                if cost_check:
                    f.write(f"can_afford={str(cost_check['can_afford']).lower()}\n")
                    f.write(f"current_usage={cost_check['current_usage']:.3f}\n")
                    f.write(f"within_warning={str(cost_check['within_warning']).lower()}\n")
                else:
                    f.write("can_afford=true\n")
        else:
            # ローカルテスト用
            print(f"is_duplicate={str(estimate.get('is_duplicate', False)).lower()}")
            print(f"estimated_cost={estimate.get('estimated_cost', {}).get('total', 0)}")
            print(f"comment_id={comment_id}")
            
    except Exception as e:
        print(f"Error: {e}")
        github_output = os.environ.get('GITHUB_OUTPUT')
        if github_output:
            with open(github_output, 'a') as f:
                f.write("is_duplicate=false\n")
                f.write("estimated_cost=0\n")
                f.write(f"error={str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()