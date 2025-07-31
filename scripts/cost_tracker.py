#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime, timedelta
from github import Github
import argparse

class CostTracker:
    def __init__(self, github_token, repo_name):
        self.github = Github(github_token)
        self.repo = self.github.get_repo(repo_name)
        self.monthly_limit = 5.0  # $5 monthly limit
        self.warning_threshold = 4.0  # $4 warning threshold
        
    def get_current_month_key(self):
        """Get current month key for tracking (YYYY-MM format)"""
        return datetime.now().strftime("%Y-%m")
        
    def get_cost_tracking_issue(self):
        """Get or create the cost tracking issue"""
        month_key = self.get_current_month_key()
        title = f"💰 Cost Tracking - {month_key}"
        
        # Search for existing cost tracking issue
        issues = self.repo.get_issues(state='open', labels=['cost-tracking'])
        for issue in issues:
            if month_key in issue.title:
                return issue
                
        # Create new cost tracking issue
        body = f"""# Monthly Cost Tracking - {month_key}

This issue tracks Claude API costs for automated bug fixing.

**Monthly Limit**: ${self.monthly_limit:.2f}
**Warning Threshold**: ${self.warning_threshold:.2f}

## Cost Log
| Date | Issue | Operation | Estimated | Actual | Running Total |
|------|-------|-----------|-----------|--------|---------------|
| - | - | - | $0.00 | $0.00 | $0.00 |

## Status
- ✅ **Under Limit**: Current usage is within monthly budget
- 📊 **Usage**: $0.00 / ${self.monthly_limit:.2f} (0%)

⚠️ **This issue is automatically managed. Do not close or modify manually.**
"""
        
        issue = self.repo.create_issue(
            title=title,
            body=body,
            labels=['cost-tracking', 'auto-generated']
        )
        return issue
        
    def parse_cost_log(self, issue_body):
        """Parse cost log from issue body"""
        costs = []
        lines = issue_body.split('\n')
        in_table = False
        
        for line in lines:
            if '| Date | Issue |' in line:
                in_table = True
                continue
            if in_table and line.startswith('|') and '|' in line and not line.startswith('|---'):
                parts = [p.strip() for p in line.split('|')[1:-1]]  # Remove empty first/last
                if len(parts) >= 6 and parts[0] != '-':
                    try:
                        actual_cost = float(parts[4].replace('$', ''))
                        costs.append({
                            'date': parts[0],
                            'issue': parts[1],
                            'operation': parts[2],
                            'estimated': float(parts[3].replace('$', '')),
                            'actual': actual_cost,
                            'running_total': float(parts[5].replace('$', ''))
                        })
                    except (ValueError, IndexError):
                        continue
                        
        return costs
        
    def get_current_usage(self):
        """Get current month's total usage"""
        issue = self.get_cost_tracking_issue()
        costs = self.parse_cost_log(issue.body)
        
        if not costs:
            return 0.0
            
        return costs[-1]['running_total']
        
    def can_afford(self, estimated_cost):
        """Check if we can afford the estimated cost"""
        current_usage = self.get_current_usage()
        projected_total = current_usage + estimated_cost
        
        return {
            'can_afford': projected_total <= self.monthly_limit,
            'current_usage': current_usage,
            'projected_total': projected_total,
            'remaining': self.monthly_limit - current_usage,
            'within_warning': projected_total <= self.warning_threshold,
            'usage_percentage': (current_usage / self.monthly_limit) * 100
        }
        
    def add_cost_entry(self, issue_number, operation, estimated_cost, actual_cost=None):
        """Add a cost entry to the tracking issue"""
        tracking_issue = self.get_cost_tracking_issue()
        current_usage = self.get_current_usage()
        
        if actual_cost is None:
            actual_cost = estimated_cost
            
        new_total = current_usage + actual_cost
        date = datetime.now().strftime("%Y-%m-%d")
        
        # Parse existing body
        lines = tracking_issue.body.split('\n')
        new_lines = []
        table_found = False
        
        for line in lines:
            if '| - | - | - | $0.00 | $0.00 | $0.00 |' in line:
                # Replace placeholder with new entry
                new_entry = f"| {date} | #{issue_number} | {operation} | ${estimated_cost:.3f} | ${actual_cost:.3f} | ${new_total:.3f} |"
                new_lines.append(new_entry)
                table_found = True
            elif line.startswith('| ') and table_found and not line.startswith('|---'):
                # Add new entry before existing entries
                new_entry = f"| {date} | #{issue_number} | {operation} | ${estimated_cost:.3f} | ${actual_cost:.3f} | ${new_total:.3f} |"
                new_lines.append(new_entry)
                new_lines.append(line)
                table_found = False
            else:
                new_lines.append(line)
                
        # Update status section
        usage_percentage = (new_total / self.monthly_limit) * 100
        status_emoji = "⚠️" if new_total >= self.warning_threshold else "✅"
        status_text = "**WARNING - Near Limit**" if new_total >= self.warning_threshold else "**Under Limit**"
        
        for i, line in enumerate(new_lines):
            if line.startswith('- ✅ **Under Limit**') or line.startswith('- ⚠️ **WARNING'):
                new_lines[i] = f"- {status_emoji} {status_text}: Current usage is {'near' if new_total >= self.warning_threshold else 'within'} monthly budget"
            elif line.startswith('- 📊 **Usage**'):
                new_lines[i] = f"- 📊 **Usage**: ${new_total:.3f} / ${self.monthly_limit:.2f} ({usage_percentage:.1f}%)"
                
        updated_body = '\n'.join(new_lines)
        tracking_issue.edit(body=updated_body)
        
        return new_total
        
    def get_cost_summary(self):
        """Get a summary of current cost status"""
        current_usage = self.get_current_usage()
        remaining = self.monthly_limit - current_usage
        usage_percentage = (current_usage / self.monthly_limit) * 100
        
        status = "🟢 SAFE"
        if current_usage >= self.monthly_limit:
            status = "🔴 LIMIT EXCEEDED"
        elif current_usage >= self.warning_threshold:
            status = "🟡 WARNING"
            
        return {
            'status': status,
            'current_usage': current_usage,
            'monthly_limit': self.monthly_limit,
            'remaining': remaining,
            'usage_percentage': usage_percentage,
            'can_continue': current_usage < self.monthly_limit
        }

def main():
    parser = argparse.ArgumentParser(description='Track Claude API costs')
    parser.add_argument('--repo', type=str, required=True)
    parser.add_argument('--action', choices=['check', 'add', 'summary'], required=True)
    parser.add_argument('--issue-number', type=int)
    parser.add_argument('--operation', type=str)
    parser.add_argument('--estimated-cost', type=float)
    parser.add_argument('--actual-cost', type=float)
    
    args = parser.parse_args()
    
    github_token = os.environ.get('GITHUB_TOKEN')
    if not github_token:
        print("Error: GITHUB_TOKEN must be set")
        sys.exit(1)
        
    tracker = CostTracker(github_token, args.repo)
    
    try:
        if args.action == 'check':
            if not args.estimated_cost:
                print("Error: --estimated-cost required for check action")
                sys.exit(1)
                
            result = tracker.can_afford(args.estimated_cost)
            
            # GitHub Actions output
            github_output = os.environ.get('GITHUB_OUTPUT')
            if github_output:
                with open(github_output, 'a') as f:
                    f.write(f"can_afford={str(result['can_afford']).lower()}\n")
                    f.write(f"current_usage={result['current_usage']:.3f}\n")
                    f.write(f"projected_total={result['projected_total']:.3f}\n")
                    f.write(f"remaining={result['remaining']:.3f}\n")
                    f.write(f"usage_percentage={result['usage_percentage']:.1f}\n")
            
            print(f"Can afford: {result['can_afford']}")
            print(f"Current usage: ${result['current_usage']:.3f}")
            print(f"Projected total: ${result['projected_total']:.3f}")
            print(f"Remaining: ${result['remaining']:.3f}")
            
        elif args.action == 'add':
            if not all([args.issue_number, args.operation, args.estimated_cost]):
                print("Error: --issue-number, --operation, --estimated-cost required for add action")
                sys.exit(1)
                
            new_total = tracker.add_cost_entry(
                args.issue_number, 
                args.operation, 
                args.estimated_cost, 
                args.actual_cost
            )
            print(f"Added cost entry. New total: ${new_total:.3f}")
            
        elif args.action == 'summary':
            summary = tracker.get_cost_summary()
            print(f"Status: {summary['status']}")
            print(f"Usage: ${summary['current_usage']:.3f} / ${summary['monthly_limit']:.2f} ({summary['usage_percentage']:.1f}%)")
            print(f"Remaining: ${summary['remaining']:.3f}")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()