export function subscriptionEnvironment(): NodeJS.ProcessEnv {
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (/^(ANTHROPIC_|CLAUDE_CODE_(?:OAUTH|API_KEY|AUTH|USE_|PROXY|GATEWAY|HOST_|CUSTOM_OAUTH|SESSION_ACCESS|EXECUTABLE)|CLAUDE_MODEL_CONFIG|CLAUDE_CONFIG_DIR)/i.test(key)) delete env[key];
  }
  return env;
}
