#!/bin/zsh
# AI Commit Message Generator
# Generates a commit message from staged changes using OpenCode with Claude Haiku

set -e

# Check if there are staged changes
DIFF=$(git diff --cached)
if [ -z "$DIFF" ]; then
  echo "No staged changes found."
  exit 1
fi

# Check if opencode is available
if ! command -v opencode &> /dev/null; then
  echo "Error: opencode is not installed or not in PATH"
  exit 1
fi

# Generate commit message using opencode with haiku model
MSG=$(opencode run -m opencode/gpt-5-nano "Generate a conventional commit message for these staged changes. Output ONLY the commit message - no explanations, no markdown, no code blocks, no quotes around the message:

$DIFF" 2>/dev/null | tail -1)

if [ -z "$MSG" ]; then
  echo "Error: Failed to generate commit message"
  exit 1
fi

# Copy to clipboard (macOS)
if command -v pbcopy &> /dev/null; then
  echo "$MSG" | pbcopy
# Linux with xclip
elif command -v xclip &> /dev/null; then
  echo "$MSG" | xclip -selection clipboard
# Linux with xsel
elif command -v xsel &> /dev/null; then
  echo "$MSG" | xsel --clipboard --input
# WSL
elif command -v clip.exe &> /dev/null; then
  echo "$MSG" | clip.exe
else
  echo "Warning: No clipboard tool found"
fi

# Output the message
echo "$MSG"
echo ""
echo "---"
echo "Copied to clipboard! Press c, then <c-o> p to paste."
