#!/usr/bin/env python3

import argparse
import json
import os
import sys
import base64
from github import Github
import anthropic
from PIL import Image
import io

class IssueAnalyzer:
    def __init__(self, github_token, claude_api_key):
        self.github = Github(github_token)
        self.claude = anthropic.Anthropic(api_key=claude_api_key)
        
    def analyze_issue(self, repo_name, issue_number):
        """GitHub Issueを分析して自動修正可能か判定"""
        repo = self.github.get_repo(repo_name)
        issue = repo.get_issue(issue_number)
        
        # Issueの内容を解析
        issue_data = self._extract_issue_data(issue)
        
        # スクリーンショットを解析
        screenshot_analysis = self._analyze_screenshots(issue)
        
        # ログを解析
        log_analysis = self._extract_logs(issue.body)
        
        # Claudeで総合的に分析
        analysis = self._claude_analyze(
            issue_data=issue_data,
            screenshot_analysis=screenshot_analysis,
            log_analysis=log_analysis
        )
        
        return analysis
        
    def _extract_issue_data(self, issue):
        """Issueから構造化データを抽出"""
        body = issue.body or ""
        
        data = {
            "title": issue.title,
            "number": issue.number,
            "labels": [label.name for label in issue.labels],
            "body": body,
            "category": None,
            "current_view": None,
            "device_info": None,
            "user_actions": [],
            "description": None
        }
        
        # カテゴリの抽出
        if "カテゴリ" in body:
            lines = body.split('\n')
            for i, line in enumerate(lines):
                if "カテゴリ" in line and i + 1 < len(lines):
                    data["category"] = lines[i].split('**')[-1].strip()
                    
        # 現在の画面の抽出
        if "現在の画面" in body:
            for line in body.split('\n'):
                if "現在の画面" in line:
                    data["current_view"] = line.split('**')[-1].strip()
                    
        # 問題の説明の抽出
        if "### 問題の説明" in body:
            start = body.find("### 問題の説明") + len("### 問題の説明")
            end = body.find("###", start)
            if end == -1:
                end = len(body)
            data["description"] = body[start:end].strip()
            
        return data
        
    def _analyze_screenshots(self, issue):
        """Issue内のスクリーンショットを解析"""
        screenshots = []
        
        # コメントからスクリーンショットを探す
        for comment in issue.get_comments():
            if "スクリーンショット" in comment.body:
                # Base64エンコードされた画像を探す
                if "data:image" in comment.body:
                    start = comment.body.find("data:image")
                    end = comment.body.find(")", start)
                    if end != -1:
                        image_data = comment.body[start:end]
                        screenshots.append(self._analyze_screenshot_data(image_data))
                        
        return screenshots
        
    def _analyze_screenshot_data(self, image_data_url):
        """スクリーンショットの内容を解析"""
        try:
            # data:image/jpeg;base64, を除去
            base64_data = image_data_url.split(',')[1]
            image_data = base64.b64decode(base64_data)
            
            # 画像をPILで開く
            image = Image.open(io.BytesIO(image_data))
            
            # 基本的な画像情報
            return {
                "width": image.width,
                "height": image.height,
                "format": image.format,
                "mode": image.mode
            }
        except Exception as e:
            return {"error": str(e)}
            
    def _extract_logs(self, body):
        """Issue本文からログを抽出"""
        logs = []
        
        if "### ログ" in body:
            start = body.find("```", body.find("### ログ"))
            end = body.find("```", start + 3)
            
            if start != -1 and end != -1:
                log_text = body[start + 3:end].strip()
                for line in log_text.split('\n'):
                    if line.strip():
                        logs.append(line)
                        
        return logs
        
    def _claude_analyze(self, issue_data, screenshot_analysis, log_analysis):
        """Claudeを使用して総合的に分析"""
        prompt = f"""
あなたはiOSアプリのバグ分析エキスパートです。
以下のバグ報告を分析して、自動修正が可能かどうか判定してください。

## バグ報告内容
タイトル: {issue_data['title']}
カテゴリ: {issue_data.get('category', '不明')}
現在の画面: {issue_data.get('current_view', '不明')}
説明: {issue_data.get('description', 'なし')}

## ラベル
{', '.join(issue_data['labels'])}

## ログ情報
{chr(10).join(log_analysis[:10]) if log_analysis else 'ログなし'}

## スクリーンショット情報
{json.dumps(screenshot_analysis, ensure_ascii=False) if screenshot_analysis else 'スクリーンショットなし'}

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

自動修正可能な条件：
1. nil参照エラー
2. 簡単な条件分岐の追加
3. UI要素の表示/非表示
4. 明らかなタイポ
5. 定数値の調整

自動修正不可の条件：
1. ビジネスロジックの変更
2. データモデルの変更
3. 複雑な状態管理
4. 3ファイル以上の変更
"""
        
        try:
            message = self.claude.messages.create(
                model="claude-3-opus-20240229",
                max_tokens=1000,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            # レスポンスからJSONを抽出
            response_text = message.content[0].text
            
            # JSON部分を探す
            start = response_text.find('{')
            end = response_text.rfind('}') + 1
            
            if start != -1 and end != 0:
                json_str = response_text[start:end]
                return json.loads(json_str)
            else:
                return {
                    "can_auto_fix": False,
                    "reason": "分析結果の解析に失敗しました"
                }
                
        except Exception as e:
            return {
                "can_auto_fix": False,
                "reason": f"Claude API エラー: {str(e)}"
            }

def main():
    parser = argparse.ArgumentParser(description='Analyze GitHub issue for auto-fix')
    parser.add_argument('--issue-number', type=int, required=True)
    parser.add_argument('--repo', type=str, required=True)
    
    args = parser.parse_args()
    
    # 環境変数から認証情報を取得
    github_token = os.environ.get('GITHUB_TOKEN')
    claude_api_key = os.environ.get('CLAUDE_API_KEY')
    
    if not github_token or not claude_api_key:
        print("Error: GITHUB_TOKEN and CLAUDE_API_KEY must be set")
        sys.exit(1)
        
    analyzer = IssueAnalyzer(github_token, claude_api_key)
    
    try:
        analysis = analyzer.analyze_issue(args.repo, args.issue_number)
        
        # GitHub Actionsの出力として設定
        print(f"::set-output name=can_auto_fix::{str(analysis.get('can_auto_fix', False)).lower()}")
        print(f"::set-output name=confidence::{analysis.get('confidence', 0)}")
        print(f"::set-output name=risk_level::{analysis.get('risk_level', 'high')}")
        print(f"::set-output name=reason::{analysis.get('reason', '')}")
        
        # 分析結果を保存
        with open('analysis_result.json', 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
            
        print(f"::set-output name=analysis::{json.dumps(analysis)}")
        
    except Exception as e:
        print(f"Error: {e}")
        print("::set-output name=can_auto_fix::false")
        print(f"::set-output name=reason::分析中にエラーが発生: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()