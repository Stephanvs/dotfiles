#!/bin/sh

TYPE=$(gum filter --limit=1 "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
SCOPE=$(gum input --placeholder "scope")

# Since the scope is optional, wrap it in parens if it has a value.
test -n "$SCOPE" && SCOPE="($SCOPE)"

# Pre-populate the input with the type(scope): so that the user may change it
SUMMARY=$(gum input --value "$TYPE$SCOPE: " --placeholder "Summary of this change")
DESCRIPTION=$(gum write --placeholder "Details of this change")

# Commit these changes if user confirms
gum style \
    --border-foreground 212 --border rounded \
    --align left --margin "0 2" --padding "1 2" \
    "$SUMMARY" "$DESCRIPTION"

if [ -n "$DESCRIPTION" ]; then
    gum confirm "Ok to commit?" && git commit -m "$SUMMARY" -m "$DESCRIPTION"
else
    gum confirm "Ok to commit?" && git commit -m "$SUMMARY"
fi
