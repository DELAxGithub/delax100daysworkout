#!/usr/bin/env python3

import argparse
import json
import os
import sys
import re

def apply_fix(fix_data):
    """修正データをファイルに適用"""
    if isinstance(fix_data, str):
        fix_data = json.loads(fix_data)
        
    if not fix_data or 'changes' not in fix_data:
        print("No changes to apply")
        return False
        
    success_count = 0
    failed_files = []
    
    for change in fix_data['changes']:
        file_path = change['file']
        original_code = change['original']
        fixed_code = change['fixed']
        
        try:
            # ファイルを読み込む
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # コードを置換
            if original_code in content:
                new_content = content.replace(original_code, fixed_code, 1)
                
                # ファイルに書き込む
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                    
                print(f"✅ Fixed: {file_path}")
                success_count += 1
            else:
                print(f"❌ Original code not found in {file_path}")
                failed_files.append(file_path)
                
                # デバッグ情報を出力
                print("Expected:")
                print(repr(original_code[:100]))
                print("\nFile content sample:")
                print(repr(content[:500]))
                
        except FileNotFoundError:
            print(f"❌ File not found: {file_path}")
            failed_files.append(file_path)
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")
            failed_files.append(file_path)
            
    # 結果をまとめる
    total_changes = len(fix_data['changes'])
    print(f"\n📊 Summary: {success_count}/{total_changes} changes applied successfully")
    
    if failed_files:
        print(f"❌ Failed files: {', '.join(failed_files)}")
        return False
        
    return True

def validate_changes(fix_data):
    """変更の妥当性を検証（safety_rules.jsonに基づく）"""
    if not fix_data or 'changes' not in fix_data:
        return False, "No changes found"
    
    # safety_rules.jsonを読み込む
    try:
        with open(os.path.join(os.path.dirname(__file__), 'safety_rules.json'), 'r') as f:
            safety_rules = json.load(f)
    except:
        # フォールバック
        safety_rules = {
            "auto_fix_config": {"max_files_per_fix": 3, "max_lines_per_fix": 100},
            "forbidden_code_patterns": [
                {"pattern": "password|secret|token", "case_sensitive": False}
            ]
        }
    
    # 禁止パターンのチェック
    for pattern_config in safety_rules.get('forbidden_code_patterns', []):
        pattern = pattern_config['pattern']
        case_sensitive = pattern_config.get('case_sensitive', False)
        
        for change in fix_data['changes']:
            fixed_code = change.get('fixed', '')
            if not case_sensitive:
                fixed_code = fixed_code.lower()
                pattern = pattern.lower()
            
            import re
            if re.search(pattern, fixed_code):
                return False, f"Forbidden pattern detected: {pattern_config.get('description', pattern)}"
    
    # ファイル数のチェック
    unique_files = set(change['file'] for change in fix_data['changes'])
    max_files = safety_rules.get('auto_fix_config', {}).get('max_files_per_fix', 3)
    if len(unique_files) > max_files:
        return False, f"Too many files affected: {len(unique_files)} (max: {max_files})"
    
    # 変更行数のチェック
    total_lines = 0
    for change in fix_data['changes']:
        original_lines = len(change.get('original', '').split('\n'))
        fixed_lines = len(change.get('fixed', '').split('\n'))
        total_lines += abs(fixed_lines - original_lines)
    
    max_lines = safety_rules.get('auto_fix_config', {}).get('max_lines_per_fix', 100)
    if total_lines > max_lines:
        return False, f"Too many lines changed: {total_lines} (max: {max_lines})"
    
    # ファイル拡張子のチェック
    allowed_extensions = safety_rules.get('allowed_file_extensions', ['.swift'])
    for change in fix_data['changes']:
        file_path = change['file']
        if not any(file_path.endswith(ext) for ext in allowed_extensions):
            return False, f"File extension not allowed: {file_path}"
    
    return True, "All checks passed"

def main():
    parser = argparse.ArgumentParser(description='Apply fix to files')
    parser.add_argument('--fix-data', type=str, required=True,
                        help='JSON string or file path containing fix data')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be changed without applying')
    
    args = parser.parse_args()
    
    # 修正データを読み込む
    try:
        if os.path.isfile(args.fix_data):
            with open(args.fix_data, 'r', encoding='utf-8') as f:
                fix_data = json.load(f)
        else:
            fix_data = json.loads(args.fix_data)
    except Exception as e:
        # デフォルトファイルを試す
        try:
            with open('fix_data.json', 'r', encoding='utf-8') as f:
                fix_data = json.load(f)
        except:
            print(f"Error loading fix data: {e}")
            sys.exit(1)
    
    # 変更の妥当性を検証
    is_valid, message = validate_changes(fix_data)
    if not is_valid:
        print(f"❌ Validation failed: {message}")
        sys.exit(1)
        
    print(f"✅ Validation passed: {message}")
    
    # ドライランモード
    if args.dry_run:
        print("\n🔍 Dry run mode - showing changes:")
        for change in fix_data['changes']:
            print(f"\nFile: {change['file']}")
            print("Original:")
            print(change['original'][:200] + "..." if len(change['original']) > 200 else change['original'])
            print("\nFixed:")
            print(change['fixed'][:200] + "..." if len(change['fixed']) > 200 else change['fixed'])
        return
    
    # 修正を適用
    if apply_fix(fix_data):
        print("\n✅ All fixes applied successfully!")
    else:
        print("\n❌ Some fixes failed to apply")
        sys.exit(1)

if __name__ == "__main__":
    main()