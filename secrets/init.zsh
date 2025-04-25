#!/bin/zsh

# Used by OpenCode
export ANTHROPIC_API_KEY=$(op read "op://Private/Anthropic Api Key/credential")
export GEMINI_API_KEY=$(op read "op://Private/Google Gemini API Key/credential")
export X_AI_API_KEY=$(op read "op://Private/X.ai API Key/credential")
export OPENAI_API_KEY=$(op read "op://Private/OpenAI API Key/credential")
