#!/usr/bin/env python3
"""
セキュリティチェックスクリプト
コミット前にAPIキーやトークンが含まれていないかチェックします
"""

import sys
import re
import os
import subprocess

# 検出パターン
SECRET_PATTERNS = [
    # GitHub Token
    (r'gh[opsu]_[A-Za-z0-9]{36}', 'GitHub Token'),
    (r'github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}', 'GitHub Personal Access Token'),
    
    # API Keys
    (r'sk-[A-Za-z0-9]{48}', 'OpenAI/Anthropic API Key'),
    (r'sk-ant-api[0-9]{2}-[A-Za-z0-9\-_]{95}', 'Anthropic API Key'),
    
    # Generic patterns
    (r'api[_-]?key["\']?\s*[:=]\s*["\'][A-Za-z0-9\-_]{20,}["\']', 'API Key'),
    (r'token["\']?\s*[:=]\s*["\'][A-Za-z0-9\-_]{20,}["\']', 'Token'),
    (r'secret["\']?\s*[:=]\s*["\'][A-Za-z0-9\-_]{20,}["\']', 'Secret'),
]

# 除外するファイル/ディレクトリ
EXCLUDE_PATHS = [
    '.git',
    '.env.example',
    'check_secrets.py',
    '__pycache__',
    '.pytest_cache',
    'node_modules',
    'build',
    'dist',
]

def check_file(filepath):
    """ファイル内の秘密情報をチェック"""
    # バイナリファイルをスキップ
    if filepath.endswith(('.png', '.jpg', '.jpeg', '.gif', '.pdf', '.zip')):
        return []
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Warning: Could not read {filepath}: {e}")
        return []
    
    found_secrets = []
    for line_num, line in enumerate(content.split('\n'), 1):
        for pattern, secret_type in SECRET_PATTERNS:
            if re.search(pattern, line, re.IGNORECASE):
                found_secrets.append({
                    'file': filepath,
                    'line': line_num,
                    'type': secret_type,
                    'content': line.strip()[:100]  # 最初の100文字のみ
                })
    
    return found_secrets

def get_staged_files():
    """Gitでステージされたファイルのリストを取得"""
    try:
        result = subprocess.run(
            ['git', 'diff', '--cached', '--name-only'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip().split('\n') if result.stdout.strip() else []
    except subprocess.CalledProcessError:
        return []

def check_all_files(check_staged_only=False):
    """すべてのファイル（またはステージされたファイルのみ）をチェック"""
    found_secrets = []
    
    if check_staged_only:
        files_to_check = get_staged_files()
    else:
        files_to_check = []
        for root, dirs, files in os.walk('.'):
            # 除外ディレクトリをスキップ
            dirs[:] = [d for d in dirs if d not in EXCLUDE_PATHS]
            
            for file in files:
                filepath = os.path.join(root, file)
                # 除外パスをチェック
                if any(exclude in filepath for exclude in EXCLUDE_PATHS):
                    continue
                files_to_check.append(filepath)
    
    for filepath in files_to_check:
        if os.path.exists(filepath):
            secrets = check_file(filepath)
            found_secrets.extend(secrets)
    
    return found_secrets

def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Check for secrets in code')
    parser.add_argument('--staged-only', action='store_true',
                        help='Check only staged files (for pre-commit hook)')
    parser.add_argument('--quiet', action='store_true',
                        help='Only show error exit code, no output')
    
    args = parser.parse_args()
    
    # チェック実行
    found_secrets = check_all_files(check_staged_only=args.staged_only)
    
    if found_secrets:
        if not args.quiet:
            print("⚠️  Found potential secrets in the following files:")
            print("=" * 60)
            
            for secret in found_secrets:
                print(f"\n📁 File: {secret['file']}")
                print(f"📍 Line: {secret['line']}")
                print(f"🔑 Type: {secret['type']}")
                print(f"📝 Content: {secret['content']}")
            
            print("\n" + "=" * 60)
            print("❌ Commit blocked! Please remove these secrets before committing.")
            print("\nTips:")
            print("- Use environment variables (.env file)")
            print("- Add sensitive files to .gitignore")
            print("- Use GitHub Secrets for CI/CD")
        
        sys.exit(1)
    else:
        if not args.quiet:
            print("✅ No secrets found!")
        sys.exit(0)

if __name__ == "__main__":
    main()