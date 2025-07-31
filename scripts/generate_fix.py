#!/usr/bin/env python3

import argparse
import json
import os
import sys
from github import Github
import anthropic

class FixGenerator:
    def __init__(self, github_token, claude_api_key):
        self.github = Github(github_token)
        self.claude = anthropic.Anthropic(api_key=claude_api_key)
        
    def generate_fix(self, repo_name, issue_number, analysis):
        """分析結果に基づいて修正コードを生成"""
        if not analysis.get('can_auto_fix', False):
            return None
            
        repo = self.github.get_repo(repo_name)
        
        # 影響を受けるファイルの内容を取得
        file_contents = self._get_file_contents(repo, analysis.get('affected_files', []))
        
        # 修正コードを生成
        fix = self._generate_fix_code(
            analysis=analysis,
            files=file_contents,
            issue_number=issue_number
        )
        
        return fix
        
    def _get_file_contents(self, repo, file_paths):
        """指定されたファイルの内容を取得"""
        contents = {}
        
        for file_path in file_paths:
            try:
                # ファイルパスの推測を実際のパスに変換
                actual_path = self._find_actual_file_path(repo, file_path)
                if actual_path:
                    file_content = repo.get_contents(actual_path)
                    if not isinstance(file_content, list):
                        contents[actual_path] = file_content.decoded_content.decode('utf-8')
            except Exception as e:
                print(f"Warning: Could not get content for {file_path}: {e}")
                
        return contents
        
    def _find_actual_file_path(self, repo, hint_path):
        """ヒントパスから実際のファイルパスを探す"""
        # よくあるパターンでファイルを探す
        possible_paths = [
            f"Delax100DaysWorkout/{hint_path}",
            f"Delax100DaysWorkout/Features/{hint_path}",
            f"Delax100DaysWorkout/Features/Today/{hint_path}",
            f"Delax100DaysWorkout/Models/{hint_path}",
            f"Delax100DaysWorkout/Services/{hint_path}",
            hint_path
        ]
        
        for path in possible_paths:
            try:
                repo.get_contents(path)
                return path
            except:
                continue
                
        # ファイル名で検索
        file_name = os.path.basename(hint_path)
        try:
            # リポジトリ内を検索（簡易版）
            contents = repo.get_contents("")
            while contents:
                file_content = contents.pop(0)
                if file_content.type == "dir":
                    contents.extend(repo.get_contents(file_content.path))
                elif file_name in file_content.path:
                    return file_content.path
        except:
            pass
            
        return None
        
    def _generate_fix_code(self, analysis, files, issue_number):
        """Claudeを使用して修正コードを生成"""
        prompt = f"""
あなたはiOSアプリ（Swift/SwiftUI）の自動バグ修正エキスパートです。
以下のバグを修正するコードを生成してください。

## バグ情報
- 原因: {analysis['root_cause']}
- 修正方針: {analysis['fix_strategy']}
- バグタイプ: {analysis['bug_type']}
- リスクレベル: {analysis['risk_level']}

## 現在のコード
"""
        
        for file_path, content in files.items():
            prompt += f"\n### {file_path}\n```swift\n{content}\n```\n"
            
        prompt += """

## 修正要件
1. 最小限の変更で問題を解決する
2. 既存のコードスタイルに従う
3. 適切なエラーハンドリングを追加
4. コメントは最小限に
5. 既存のテストを壊さない

以下のJSON形式で修正内容を返してください：
{
    "changes": [
        {
            "file": "ファイルパス",
            "original": "元のコード（完全一致する必要がある）",
            "fixed": "修正後のコード",
            "line_start": 開始行番号（推定）,
            "line_end": 終了行番号（推定）
        }
    ],
    "summary": "修正内容の要約",
    "test_suggestions": ["推奨されるテスト"],
    "confidence": 0-100
}

重要: originalフィールドには、実際のファイルに存在する完全に一致するコードを含めてください。
空白、インデント、改行も正確に一致させる必要があります。
"""
        
        try:
            message = self.claude.messages.create(
                model="claude-opus-4-20250514",
                max_tokens=2000,
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
                fix_data = json.loads(json_str)
                
                # 修正の妥当性をチェック
                fix_data = self._validate_fix(fix_data, files)
                
                return fix_data
            else:
                return None
                
        except Exception as e:
            print(f"Error generating fix: {e}")
            return None
            
    def _validate_fix(self, fix_data, original_files):
        """修正の妥当性を検証"""
        validated_changes = []
        
        for change in fix_data.get('changes', []):
            file_path = change['file']
            original_code = change['original']
            
            # ファイルが存在するか確認
            if file_path in original_files:
                file_content = original_files[file_path]
                
                # 元のコードが実際に存在するか確認
                if original_code in file_content:
                    validated_changes.append(change)
                else:
                    # 空白の違いを無視して再度チェック
                    normalized_original = ' '.join(original_code.split())
                    normalized_content = ' '.join(file_content.split())
                    
                    if normalized_original in normalized_content:
                        # 実際のコードを探す
                        lines = file_content.split('\n')
                        for i, line in enumerate(lines):
                            if original_code.strip().split('\n')[0].strip() in line:
                                # 実際のコードを抽出
                                actual_code = self._extract_code_block(lines, i)
                                if actual_code:
                                    change['original'] = actual_code
                                    validated_changes.append(change)
                                break
                                
        fix_data['changes'] = validated_changes
        return fix_data
        
    def _extract_code_block(self, lines, start_index):
        """コードブロックを抽出"""
        # 簡易的な実装（実際にはもっと複雑な処理が必要）
        indent = len(lines[start_index]) - len(lines[start_index].lstrip())
        
        code_lines = [lines[start_index]]
        i = start_index + 1
        
        while i < len(lines):
            line = lines[i]
            if line.strip() and len(line) - len(line.lstrip()) <= indent:
                break
            code_lines.append(line)
            i += 1
            
        return '\n'.join(code_lines)

def main():
    parser = argparse.ArgumentParser(description='Generate fix for GitHub issue')
    parser.add_argument('--issue-number', type=int, required=True)
    parser.add_argument('--repo', type=str, required=True)
    parser.add_argument('--analysis', type=str, required=True)
    
    args = parser.parse_args()
    
    # 環境変数から認証情報を取得
    github_token = os.environ.get('GITHUB_TOKEN')
    claude_api_key = os.environ.get('CLAUDE_API_KEY')
    
    if not github_token or not claude_api_key:
        print("Error: GITHUB_TOKEN and CLAUDE_API_KEY must be set")
        sys.exit(1)
        
    # 分析結果を読み込む
    try:
        analysis = json.loads(args.analysis)
    except:
        # ファイルから読み込む
        with open('analysis_result.json', 'r', encoding='utf-8') as f:
            analysis = json.load(f)
    
    generator = FixGenerator(github_token, claude_api_key)
    
    try:
        fix_data = generator.generate_fix(args.repo, args.issue_number, analysis)
        
        if fix_data and fix_data.get('changes'):
            # GitHub Actionsの出力として設定（新しい形式）
            github_output = os.environ.get('GITHUB_OUTPUT')
            changed_files_count = len(set(c['file'] for c in fix_data['changes']))
            total_lines = sum(
                len(c['fixed'].split('\n')) - len(c['original'].split('\n'))
                for c in fix_data['changes']
            )
            
            if github_output:
                with open(github_output, 'a') as f:
                    f.write("has_fix=true\n")
                    f.write(f"fix_summary={fix_data.get('summary', '')}\n")
                    f.write(f"changed_files_count={changed_files_count}\n")
                    f.write(f"changed_lines_count={abs(total_lines)}\n")
                    f.write(f"risk_level={analysis.get('risk_level', 'medium')}\n")
            else:
                # フォールバック（ローカルテスト用）
                print("has_fix=true")
                print(f"fix_summary={fix_data.get('summary', '')}")
                print(f"changed_files_count={changed_files_count}")
                print(f"changed_lines_count={abs(total_lines)}")
            
            # 修正データを保存
            with open('fix_data.json', 'w', encoding='utf-8') as f:
                json.dump(fix_data, f, ensure_ascii=False, indent=2)
        else:
            github_output = os.environ.get('GITHUB_OUTPUT')
            if github_output:
                with open(github_output, 'a') as f:
                    f.write("has_fix=false\n")
                    f.write("fix_summary=修正コードの生成に失敗しました\n")
            
    except Exception as e:
        print(f"Error: {e}")
        github_output = os.environ.get('GITHUB_OUTPUT')
        if github_output:
            with open(github_output, 'a') as f:
                f.write("has_fix=false\n")
        sys.exit(1)

if __name__ == "__main__":
    main()