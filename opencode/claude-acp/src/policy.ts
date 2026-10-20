export const toolNames = ['Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash'] as const;

export function sessionOptions() {
  return {
    settings: { permissions: { ask: ['*'], allow: [], deny: [], defaultMode: 'default' }, fastMode: false, fastModePerSessionOptIn: true },
    settingSources: [],
    allowDangerouslySkipPermissions: false,
    tools: [...toolNames],
    disallowedTools: ['Agent', 'Task', 'TaskOutput', 'TaskStop', 'EnterPlanMode', 'ExitPlanMode'],
    promptSuggestions: false,
    strictMcpConfig: true,
    env: { CLAUDE_CODE_DISABLE_BACKGROUND_TASKS: '1' },
  };
}
