#!/usr/bin/env bash

# Terminate execution immediately if any command fails
set -e

# Terminal output colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}       AUTOMATED INFRASTRUCTURE SETUP (LINT, TEST, CI)         ${NC}"
echo -e "${CYAN}================================================================${NC}"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${RED}Error: Working directory has uncommitted changes.${NC}"
  echo "Please commit or stash your changes before running this script."
  exit 1
fi

# ----------------------------------------------------------------
# Step 1: Base setup (main and integration branch)
# ----------------------------------------------------------------
echo -e "\n${YELLOW}==> [1/5] Setting up base integration branch: setup-infra...${NC}"
git checkout main
git pull origin main || true
git checkout -B setup-infra

# ----------------------------------------------------------------
# Step 2: Feature Branch - Lint (ESLint)
# ----------------------------------------------------------------
echo -e "\n${YELLOW}==> [2/5] Creating branch 'feature/lint' and installing ESLint...${NC}"
git checkout -B feature/lint

# Install ESLint
npm install -D eslint

# Generate modern flat ESLint configuration
cat << 'EOF' > eslint.config.js
export default [
  {
    ignores: ["dist/**", ".astro/**", "node_modules/**"]
  },
  {
    files: ["**/*.{js,mjs,cjs,ts}"],
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "warn"
    }
  }
];
EOF

# Add lint script to package.json
npm pkg set scripts.lint="eslint ."

# Stage, commit and test
git add package.json package-lock.json eslint.config.js
git commit -m "chore(lint): install and configure eslint"

echo -e "${GREEN}Running ESLint verification...${NC}"
npm run lint

# Merge into setup-infra
git checkout setup-infra
git merge --no-ff feature/lint -m "Merge branch 'feature/lint' into setup-infra"
echo -e "${GREEN}✔ ESLint successfully configured, verified, and merged!${NC}"

# ----------------------------------------------------------------
# Step 3: Feature Branch - Vitest
# ----------------------------------------------------------------
echo -e "\n${YELLOW}==> [3/5] Creating branch 'feature/vitest' and installing Vitest...${NC}"
git checkout -B feature/vitest

# Install Vitest
npm install -D vitest

# Add test script to package.json
npm pkg set scripts.test="vitest run"

# Create a sample unit test so Vitest doesn't fail on empty search
mkdir -p test
cat << 'EOF' > test/example.test.js
import { test, expect } from 'vitest';

test('basic sanity check: 1 + 1 equals 2', () => {
  expect(1 + 1).toBe(2);
});
EOF

# Stage, commit and test
git add package.json package-lock.json test/example.test.js
git commit -m "test(vitest): install vitest and add initial sanity test"

echo -e "${GREEN}Running Vitest verification...${NC}"
npm run test

# Merge into setup-infra
git checkout setup-infra
git merge --no-ff feature/vitest -m "Merge branch 'feature/vitest' into setup-infra"
echo -e "${GREEN}✔ Vitest successfully configured, verified, and merged!${NC}"

# ----------------------------------------------------------------
# Step 4: Feature Branch - GitHub Actions
# ----------------------------------------------------------------
echo -e "\n${YELLOW}==> [4/5] Creating branch 'feature/actions' and configuring CI workflow...${NC}"
git checkout -B feature/actions

# Create GitHub Actions CI workflow file
mkdir -p .github/workflows
cat << 'EOF' > .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main, setup-infra ]
  pull_request:
    branches: [ main, setup-infra ]

jobs:
  validate:
    name: Lint & Test Verification
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js runtime
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install dependencies
        run: npm ci || npm install

      - name: Run code linter
        run: npm run lint

      - name: Run test suite
        run: npm run test
EOF

# Stage and commit workflow
git add .github/workflows/ci.yml
git commit -m "ci: add github actions workflow for lint and test"

# Merge into setup-infra
git checkout setup-infra
git merge --no-ff feature/actions -m "Merge branch 'feature/actions' into setup-infra"
echo -e "${GREEN}✔ GitHub Actions workflow created and merged!${NC}"

# ----------------------------------------------------------------
# Step 5: Final Verification & Git Tree Display
# ----------------------------------------------------------------
echo -e "\n${YELLOW}==> [5/5] Performing final full sanity checks on 'setup-infra'...${NC}"
npm run lint
npm run test

echo -e "\n${CYAN}Generated Git Commit Graph:${NC}"
git log --graph --oneline --decorate -n 12

# ----------------------------------------------------------------
# Interruption / Pause Point before main
# ----------------------------------------------------------------
echo -e "\n${YELLOW}================================================================${NC}"
echo -e "${YELLOW}🛑 PAUSE: The 'setup-infra' branch is fully built and tested!${NC}"
echo -e "All 3 feature branches have been merged into 'setup-infra'."
echo -e "You are currently 1 step away from merging everything into ${GREEN}main${NC}."
echo -e "${YELLOW}================================================================${NC}"

read -r -p "Do you want to merge 'setup-infra' into 'main' right now? [y/N]: " choice

case "$choice" in 
  [yY][eE][sS]|[yY])
    echo -e "\n${GREEN}Merging 'setup-infra' into 'main'...${NC}"
    git checkout main
    git merge --no-ff setup-infra -m "feat(infra): integrate eslint, vitest, and github actions pipeline"
    echo -e "\n${GREEN}✔ SUCCESS: Project infrastructure is completely configured in 'main'!${NC}"
    echo -e "To upload changes to GitHub, run: ${CYAN}git push origin main${NC}"
    ;;
  *)
    echo -e "\n${CYAN}Merge aborted by user.${NC}"
    echo -e "You are still on branch: ${YELLOW}setup-infra${NC}"
    echo -e "You can now push it to GitHub and open a Pull Request manually:"
    echo -e "${CYAN}git push -u origin setup-infra${NC}"
    ;;
esac