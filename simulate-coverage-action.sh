#!/bin/bash
set -e  # Exit on error

echo "=================================================="
echo "🚀 Simulating GitHub Action: Test Coverage"
echo "=================================================="
echo ""

# Step 1: Setup (already done - Flutter is installed)
echo "✓ Step 1: Checkout repository (simulated - already in repo)"
echo ""

# Step 2: Setup Flutter
echo "✓ Step 2: Setup Flutter (simulated - using existing Flutter installation)"
echo ""

# Step 3: Install dependencies
echo "📦 Step 3: Install dependencies"
echo "Running: flutter pub get"
flutter pub get
echo ""

# Step 4: Run tests with coverage
echo "🧪 Step 4: Run tests with coverage"
echo "Running: flutter test --coverage"
flutter test --coverage
echo ""

# Step 5: Install lcov
echo "🔧 Step 5: Install lcov"
if command -v lcov &> /dev/null; then
    echo "lcov already installed: $(lcov --version | head -1)"
else
    echo "Installing lcov..."
    sudo apt-get update -qq
    sudo apt-get install -y lcov
fi
echo ""

# Step 6: Verify coverage file exists
echo "✅ Step 6: Verify coverage file exists"
if [ ! -f coverage/lcov.info ]; then
    echo "❌ Error: coverage/lcov.info not found!"
    exit 1
fi
echo "Coverage file size: $(wc -c < coverage/lcov.info) bytes"
echo "Coverage file lines: $(wc -l < coverage/lcov.info) lines"
echo ""

# Step 7: Extract coverage percentage
echo "📊 Step 7: Extract coverage percentage"
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')
echo "percentage=$COVERAGE"
echo "Coverage: $COVERAGE"
echo ""

# Step 8: Generate detailed coverage list
echo "📋 Step 8: Generate detailed coverage list"
lcov --list coverage/lcov.info > coverage-list.txt 2>&1
echo "Detailed coverage report generated"
echo "First 30 lines of coverage-list.txt:"
head -30 coverage-list.txt
echo ""

# Step 9: Simulate PR comment generation
echo "💬 Step 9: Comment PR with coverage (simulated)"
echo "Running Node.js script to generate comment..."
echo ""

cat > /tmp/simulate-pr-comment.js << 'EOF'
const fs = require('fs');

// Simulate GitHub Action outputs
const coverage = process.env.COVERAGE;

// Read the coverage list file that was generated in the previous step
const lcovOutput = fs.readFileSync('coverage-list.txt', 'utf-8');

// Parse coverage percentage
const coverageNum = parseFloat(coverage);
const emoji = coverageNum >= 80 ? '✅' : coverageNum >= 60 ? '⚠️' : '❌';

const comment = `## ${emoji} Test Coverage Report

**Overall Coverage: ${coverage}**

<details>
<summary>📊 Detailed Coverage</summary>

\`\`\`
${lcovOutput}
\`\`\`

</details>

---
*Coverage threshold: ✅ ≥80% | ⚠️ ≥60% | ❌ <60%*
`;

console.log('================================================');
console.log('📝 SIMULATED PR COMMENT');
console.log('================================================');
console.log(comment);
console.log('================================================');
console.log('✅ Comment would be posted to PR');
console.log('================================================');

// Save the comment to a file
fs.writeFileSync('coverage/simulated-pr-comment.md', comment);
console.log('\n💾 Comment saved to: coverage/simulated-pr-comment.md');
EOF

COVERAGE=$COVERAGE node /tmp/simulate-pr-comment.js
echo ""

# Step 10: Summary
echo "=================================================="
echo "✅ GitHub Action Simulation Complete!"
echo "=================================================="
echo ""
echo "Summary:"
echo "  - Tests passed: ✅"
echo "  - Coverage generated: ✅"
echo "  - Coverage percentage: $COVERAGE"
echo "  - Detailed report: coverage-list.txt"
echo "  - PR comment preview: coverage/simulated-pr-comment.md"
echo ""
echo "Files created:"
echo "  - coverage/lcov.info"
echo "  - coverage-list.txt"
echo "  - coverage/simulated-pr-comment.md"
echo ""
echo "Next steps:"
echo "  - Review coverage/simulated-pr-comment.md to see the PR comment"
echo "  - Open coverage/html/index.html in a browser for detailed coverage"
echo ""

# Cleanup temp file
rm -f /tmp/simulate-pr-comment.js

exit 0
