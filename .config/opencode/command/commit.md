---
description: Generate commit message and commit changes
agent: build
---

First, check the git status:
!`git status --porcelain`

If there are no changes (empty output), inform me "Nothing to commit" and stop.

If there ARE changes, analyze them:
!`git diff`
!`git diff --cached`

User provided hint/message: $ARGUMENTS

Follow these rules:

1. If "$ARGUMENTS" is empty:
   - Analyze the diff and generate a commit message automatically

2. If "$ARGUMENTS" starts with a valid prefix (feat:, fix:, bug:, wip:, ci:, docs:, refactor:, test:, chore:, build:, revert:):
   - Use the user's message exactly as provided

3. If "$ARGUMENTS" has text but no valid prefix:
   - Use it as a hint to generate a properly formatted commit message

Commit message rules:
- MUST be a single line only
- MUST start with one of: feat:, fix:, bug:, wip:, ci:, docs:, refactor:, test:, chore:, build:, revert:
- Keep it short and concise (under 72 characters ideally)
- Lowercase after the prefix
- No period at the end
- Describe WHAT changed, not HOW

Examples:
- feat: add user authentication endpoint
- fix: resolve null pointer in payment processing
- wip: implement search functionality
- ci: update github actions workflow
- refactor: simplify database connection logic
- docs: update installation instructions
- chore: update dependencies

After generating the message:
1. Stage all changes: `git add -A`
2. Commit with the message: `git commit -m "your generated message"`
3. Show the result: `git log -1 --oneline`
