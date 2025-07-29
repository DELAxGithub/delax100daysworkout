#!/usr/bin/env python3
"""
Xcodeプロジェクトに新しいファイルを追加するスクリプト
"""
import os
import sys
import uuid
import re
from pathlib import Path

class XcodeProjectUpdater:
    def __init__(self, project_path):
        self.project_path = project_path
        self.pbxproj_path = os.path.join(project_path, "project.pbxproj")
        self.content = self._read_project()
        
    def _read_project(self):
        """プロジェクトファイルを読み込む"""
        with open(self.pbxproj_path, 'r', encoding='utf-8') as f:
            return f.read()
    
    def _write_project(self):
        """プロジェクトファイルを書き込む"""
        with open(self.pbxproj_path, 'w', encoding='utf-8') as f:
            f.write(self.content)
    
    def _generate_uuid(self):
        """Xcode形式のUUIDを生成"""
        return uuid.uuid4().hex[:24].upper()
    
    def add_swift_file(self, file_path, group_path):
        """Swiftファイルをプロジェクトに追加"""
        file_name = os.path.basename(file_path)
        file_ref_uuid = self._generate_uuid()
        build_file_uuid = self._generate_uuid()
        
        # PBXFileReferenceセクションに追加
        file_ref = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n'
        
        # PBXFileReferenceセクションを探して追加
        file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/\n(.*?)/\* End PBXFileReference section \*/', self.content, re.DOTALL)
        if file_ref_section:
            # セクションの最後に追加
            insert_pos = file_ref_section.end() - len('/* End PBXFileReference section */')
            self.content = self.content[:insert_pos] + file_ref + self.content[insert_pos:]
        
        # PBXBuildFileセクションに追加
        build_file = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n'
        
        build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/\n(.*?)/\* End PBXBuildFile section \*/', self.content, re.DOTALL)
        if build_file_section:
            insert_pos = build_file_section.end() - len('/* End PBXBuildFile section */')
            self.content = self.content[:insert_pos] + build_file + self.content[insert_pos:]
        
        # グループに追加
        self._add_to_group(file_ref_uuid, file_name, group_path)
        
        # ソースビルドフェーズに追加
        self._add_to_build_phase(build_file_uuid, file_name)
        
        print(f"✅ Added {file_name} to Xcode project")
        
    def _add_to_group(self, file_ref_uuid, file_name, group_path):
        """ファイルをグループに追加"""
        # グループパスに基づいて適切なグループを見つける
        group_components = group_path.split('/')
        
        # まずは該当するグループを探す
        for component in group_components:
            group_pattern = rf'{component} /\* {component} \*/ = {{[^}}]*?children = \(([^)]*?)\);'
            match = re.search(group_pattern, self.content, re.DOTALL)
            if match:
                children_content = match.group(1)
                if file_ref_uuid not in children_content:
                    # 子要素リストに追加
                    new_children = children_content.rstrip() + f'\n\t\t\t\t{file_ref_uuid} /* {file_name} */,\n\t\t\t'
                    self.content = self.content.replace(children_content, new_children)
                break
    
    def _add_to_build_phase(self, build_file_uuid, file_name):
        """ソースビルドフェーズに追加"""
        # Sources build phaseを探す
        sources_pattern = r'Sources /\* Sources \*/ = {[^}]*?files = \(([^)]*?)\);'
        match = re.search(sources_pattern, self.content, re.DOTALL)
        if match:
            files_content = match.group(1)
            if build_file_uuid not in files_content:
                new_files = files_content.rstrip() + f'\n\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,\n\t\t\t'
                self.content = self.content.replace(files_content, new_files)

def main():
    if len(sys.argv) < 3:
        print("Usage: python add_to_xcode.py <file_path> <group_path>")
        print("Example: python add_to_xcode.py Models/NewModel.swift Models")
        sys.exit(1)
    
    file_path = sys.argv[1]
    group_path = sys.argv[2]
    
    # プロジェクトパスを探す
    project_path = None
    for root, dirs, files in os.walk('.'):
        for dir in dirs:
            if dir.endswith('.xcodeproj'):
                project_path = os.path.join(root, dir)
                break
        if project_path:
            break
    
    if not project_path:
        print("❌ Xcode project not found")
        sys.exit(1)
    
    updater = XcodeProjectUpdater(project_path)
    updater.add_swift_file(file_path, group_path)
    updater._write_project()
    
    print(f"✅ Successfully updated {project_path}")

if __name__ == "__main__":
    main()