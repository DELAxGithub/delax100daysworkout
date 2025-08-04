#!/bin/bash

# Watch Mode for Delax100DaysWorkout
# Usage: ./watch-mode.sh

set -e

echo "🔍 Starting Watch Mode for Delax100DaysWorkout"
echo "📁 Monitoring: Delax100DaysWorkout/**/*.swift"
echo "⚙️  Config: auto-fix-config.yml"
echo ""

# Check if config exists
if [ ! -f "auto-fix-config.yml" ]; then
    echo "❌ auto-fix-config.yml not found"
    exit 1
fi

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY environment variable not set"
    echo "💡 Please set your Claude API key:"
    echo "   export ANTHROPIC_API_KEY=\"your-api-key\""
    exit 1
fi

# Run watch mode
echo "🚀 Starting continuous monitoring..."
./auto-fix-scripts/watch-and-fix.sh