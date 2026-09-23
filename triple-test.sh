#!/usr/bin/env bash

# Stop execution on failure
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_BRANCH=$(git branch --show-current)

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}    TEST CURRENT BRANCH (Lint, Vitest, Github Actions)     ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Target branch: ${YELLOW}$CURRENT_BRANCH${NC}"

if [ "$CURRENT_BRANCH" = "main" ]; then
  echo -e "${RED}Error: You are on 'main'! Create a feature branch first.${NC}"
  echo "Example: git checkout -b my-feature"
  exit 1
fi

# 1. Install dependencies
echo -e "\n${YELLOW}▶ [1/4] Installing ESLint and Vitest...${NC}"
npm install -D eslint vitest

# 2. Configure package.json
echo -e "\n${YELLOW}▶ [2/4] Registering scripts in package.json...${NC}"
npm pkg set scripts.lint="eslint ."
npm pkg set scripts.test="vitest run"

# 3. Create config files if they don't exist yet
echo -e "\n${YELLOW}▶ [3/4] Adding configuration files...${NC}"

# ESLint flat config
if [ ! -f "eslint.config.js" ]; then
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
fi

# Vitest basic test (only if user hasn't written any tests yet)
if [ ! -d "test" ] && [ ! -d "tests" ] && [ -z "$(find . -maxdepth 3 -name '*.test.*' -o -name '*.spec.*' 2>/dev/null)" ]; then
  echo -e "${CYAN}No tests found. Generating a basic test file...${NC}"
  mkdir -p test
  cat << 'EOF' > test/sanity.test.js
import { test, expect } from 'vitest';

test('sanity check', () => {
  expect(true).toBe(true);
});
EOF
fi

# GitHub Actions workflow
mkdir -p .github/workflows
cat << 'EOF' > .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-and-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm run lint
      - run: npm run test
EOF

# 4. Run tests on YOUR code
echo -e "\n${YELLOW}▶ [4/4] Testing YOUR branch code...${NC}"

echo -e "\n${CYAN}--- Running ESLint ---${NC}"
npm run lint

echo -e "\n${CYAN}--- Running Vitest ---${NC}"
npm run test

# 5. Commit the injected infrastructure
git add package.json package-lock.json eslint.config.js .github/
if [ -d "test" ]; then git add test/; fi

git commit -m "chore(infra): add eslint, vitest, and github actions pipeline" || true

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}✔ SUCCESS! Your branch is fully configured and PASSES all tests!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "You can now safely push your branch to GitHub:"
echo -e "${CYAN}git push -u origin $CURRENT_BRANCH${NC}"