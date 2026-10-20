# Claude ACP provider for OpenCode 2.0.32

Local V2 plugin and native provider. Requests run the real `claude-agent-acp`
adapter using Claude Code's existing sign-in. There is no HTTP proxy, copied
credential, or AI-SDK provider shim.

## Build and load

Requires Windows, Node 22+, an installed `claude.exe` on PATH with a working
Claude Code subscription sign-in, and OpenCode **2.0.32**. Other versions and
operating systems are not verified.

```sh
cd opencode/claude-acp
npm ci --ignore-scripts
npm run build
npm run check
npm test
```

The package root is the local plugin directory. Its `server.js` loads
`dist/index.js`, which selects a content-addressed runtime under
`dist/runtime/<hash>/`. The plugin registers that generation's `provider.js` as
the separate native provider module. `dist/provider.js` remains the direct
provider export; do not pin it as the plugin's configured runtime.

Configure the plugin **directory**, not an individual module, in OpenCode's
`plugins` list. With this package linked beside the global config, use
`"./claude-acp"`. Do not configure the provider module as a plugin. The plugin
registers provider `claude-acp`; select, for example, `claude-acp/sonnet`.
It does not change your default model or authenticate on your behalf. Missing
adapter/authentication is an error, not a fallback to another provider.

Select **Claude (ACP)** in `/models`, or run:

```sh
opencode2 run --model claude-acp/sonnet "Your request"
```

The dotfiles PowerShell installer installs the pinned dependencies, builds the
package, and creates a missing config-directory junction without elevation.
The zsh installer also builds and links the package, but the runtime remains
Windows-only. Rebuild before starting work, not during an active Claude turn.

Default discovery and inference resolve `claude.exe` from absolute PATH entries
and pass its verified absolute file path through the supported
`CLAUDE_CODE_EXECUTABLE` option after environment scrubbing. They never search
the session's current directory or inherit a stale executable override. A missing
installed CLI fails clearly; there is no silent SDK-bundled CLI fallback.
Explicit custom `adapterCommand` settings retain their own executable selection
and do not require Claude CLI. Their environment remains scrubbed.

The measured installed CLI `C:/Users/stephanvs/.local/bin/claude.exe` version
2.1.303 answered through the real ACP protocol with Sonnet. The SDK-bundled
CLI 2.1.300 returned an out-of-extra-usage error for Sonnet and Haiku in the same
account experiment. Selecting the installed CLI was sufficient to change that
result; this does not establish the vendor's underlying cause. No credential,
HTTP-header, account, or billing changes were involved.

Models are discovered at plugin startup from real ACP `configOptions`, not a
hard-coded Anthropic catalog. The observed IDs were `default`, `opus`, `sonnet`,
`fable`, `haiku`, `claude-haiku-4-5-20251001`, `claude-sonnet-5`, `claude-opus-5`,
`claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, and
`claude-sonnet-4-6`. Availability and alias targets can change with the account.
The adapter's context budget of 100,000 and output budget of 8,000 are conservative
OpenCode bookkeeping defaults, **not provider-advertised limits**. ACP does not
guarantee enforcement of OpenCode generation options. Pricing is left unknown.
ACP usage is not yet mapped into OpenCode's token counters. Do not treat those
counters as a subscription quota meter; very long conversations can still hit
Claude's context limits.

## Conversation and tools

Every inference owns a fresh subprocess and ACP session. OpenCode remains the
conversation owner. Claude keeps its default native Claude Code system prompt:
the adapter never supplies ACP `session/new.systemPrompt`.

One delegated user prompt explicitly identifies `caller: "OpenCode"`. Its JSON
envelope contains unchanged `callerInstructions` text, role-tagged `history`
including tool outcomes, and a separate actionable `currentRequest`. Caller
instructions are user-level desired context, subordinate to Claude's native
system. They are not promoted into a replacement persona or native tool schema.
No OpenCode identity strings or caller instruction content are filtered or
rewritten. History is labelled non-actionable and sent once, never replayed as
new requests. The fixed preface also prevents caller-provided leading slash
commands from being interpreted as ACP-local commands.

This is contextual role replay, not import of an arbitrary Claude transcript or
restoration of private transcript files, prompt cache, or exact native role
semantics. History labels are not a security sandbox. Tool access, permission
decisions, modes and process lifetime are enforced by code, not caller wording.

Text and reasoning become native events. A hosted tool is announced immediately
with `tool-input-start`; definitive permission input becomes a native tool call
before execution. The transport waits for the consumer's next pull before
permission can pass, so call processing precedes the side effect. Calls/results
carry `providerExecuted: true`. Interrupted attempts therefore retain their
pending native record. A completed tool without a permission request fails
closed; failed tool updates retain their exact raw error. A failed ACP status
alone does not prove an operation had no side effects. Only
explicit ACP stop reasons can finish a successful stream. Read, Write, Edit, Glob, Grep and
Bash are the only exposed tools. Images/media are rejected rather than dropped.
OpenCode tools, MCP servers, delegation, interactive questions, and background
tasks are not exposed to Claude. There is no automatic retry after a failure.

Discovery starts a native session without any caller system override, sends no
prompts, and rejects tool permissions. Generation without an identified OpenCode session fails closed.
Auxiliary title/generate/compaction calls cannot approve tools.

## Permission boundary

Session settings use `ask: ['*']`, empty allow/deny rules, `settingSources: []`,
`allowDangerouslySkipPermissions: false`, and an explicit switch to `default`
mode. `strictMcpConfig: true` also prevents ambient MCP configuration. Fast mode
is off in session settings and explicitly switched off when ACP advertises the
toggle. The adapter never enables account extra usage; account-side quota and
billing decisions can still reject a request. No Claude approval is persisted.
Each request uses the location's opaque
broker capability and the actual OpenCode session agent from `session.get`.
Unknown tools fail closed. Inputs come from `rawInput`, never presentation titles.

Mappings: Read to `read`; Write/Edit to `edit`; Glob to `glob`; Grep to `grep`;
Bash to V2 `shell`. Shell policy is checked **before** the broader directory
check, so a denied shell command does not request broader access. File actions resolve paths against the actual session cwd,
including existing symlinks, and require `external_directory` for outside paths.
Glob/Grep use the pattern as their action resource. Every Bash request also
requires `external_directory: '*'`: arbitrary shell text cannot be safely
path-parsed. This deliberately asks more broadly than OpenCode's native Bash
tool. Explicit background inputs and obvious background shell syntax are denied.
The conservative check rejects any `&`, including `&&` and `2>&1`; use separate
foreground commands instead.
Allowing arbitrary shell code is not a sandbox and can spawn descendants or
access files itself; only approve commands you trust. The process tree is killed
at invocation cleanup. User-provided hooks/settings are not loaded.

The plugin uses the Effect-native permission API. Each assertion and session
lookup runs with the invocation's AbortSignal; Effect interruption removes its
pending ask, including delayed admission, without listing or replying to foreign
requests. ACP receives cancel and close. A PowerShell guardian creates a Windows
Job Object with kill-on-close, creates the adapter suspended, assigns it before
resuming, and owns every descendant. Before launch it opens a synchronization
handle to the exact OpenCode parent PID; failure to open that handle fails closed
without launching the adapter. It waits on both the adapter and parent handles.
Either adapter exit or owning-parent death terminates the job and waits for it
to become empty, so a parent crash does not depend on cooperative ACP EOF disposal.
The process-boundary test kills only the model host, records host/guardian/adapter/
grandchild identities, and verifies their disappearance and absence of a delayed
side-effect sentinel. Closing or terminating the guardian closes the job, including after
successful inference. Cleanup timeout/guardian errors are surfaced rather than
falling back to a parent-only kill. No process-tree polling is used in production.
This is process ownership, not a sandbox for external effects or remote services.

The child environment strips conflicting Anthropic API credentials/base URLs,
Claude OAuth token overrides, stale CLI overrides, and provider-routing overrides. It preserves OS
environment, HOME/USERPROFILE and PATH, and uses Claude CLI's saved sign-in.
No credentials are read, copied, or written by the plugin. Inheriting a future
API key must not silently convert this subscription provider to paid API use.
Only default Claude adapter launches then receive the deliberately resolved
installed CLI path; no diagnostic launcher is shipped.

## Verification

### Reload and location isolation

OpenCode 2.0.32 reloads a plugin's static module graph but caches native provider
modules by entrypoint for the service lifetime. A module-private broker Map can
therefore split from a cached provider after a reload or an alias-path load.
Broker capabilities now share a versioned process registry keyed only by random
per-activation IDs. Unloading an activation deletes exactly its own entry; an
unknown or disposed ID still fails closed. The request hook attaches the current
activation's broker ID, never a global current session or a search across brokers.

Builds stage TypeScript output and publish a complete, immutable runtime graph
before atomically updating the plugin entry. Its content-addressed provider URL
bypasses old native module caches without restarting the shared service. Keep
previous runtime generations while that service might still reference them.
This does not relax tool permissions or change the OpenCode default model.

### Recorded checks

Task evidence directory:
`C:/Users/stephanvs/AppData/Local/Temp/opencode/claude-acp-integration/`.

- `broker-reload-evidence.json`: the module-instance regression failed before
  the fix and passed afterward; all 18 process-boundary tests passed. One private
  host loaded direct and alias paths, enforced a real write denial, unloaded and
  reloaded one location, and kept the other location independent. A new task-owned
  session on the existing shared service also succeeded without changing its PID.
- `parent-lifetime-evidence.json`: build, typecheck and all 17 process-boundary
  tests passed. An abrupt model-host kill left no captured guardian, adapter or
  grandchild alive, and no delayed sentinel appeared. No pre-fix red is claimed.
- `verification/live-UACytM/report.json`: 65 live core assertions passed with
  zero failures. These cover stored history, context recall, read/edit decisions,
  concurrent session isolation, server restart and Sonnet/Haiku switching.
- `verification/live-eKFUw6/report.json`: all 66 live safety assertions passed
  on the final reload-safe runtime,
  with zero failures or blocked checks. Actual inference, pending permissions,
  and a foreground shell were interrupted. Captured descendants exited, pending
  requests cleared without a reply, no delayed write occurred, and sessions recovered.
- `global-switch-report.json`: the installed global config passed a real Claude
  to OpenAI to Claude conversation in one session, without a project override.
  OpenAI recovered a secret present only in the preceding hosted Read result.
  Returning Claude recovered the intervening OpenAI turn. The default model
  remained unchanged and the incompatible bridge entry was absent.

The live runs loaded the package through the real config-directory path and used
OpenCode's public API. They did not restart the user's shared service or edit its
database. Earlier failed experiments remain in the task directory for audit.
The core report leaves OS-level syscall counting and simultaneous writes with
opposing permissions unmeasured. Its cross-provider case was exercised separately
by `verify-switch.mjs`, not by the private server's unauthenticated native provider.

Rerun the live suites from the task evidence directory:

```sh
node verification/verify.mjs --live --plugin "$HOME/.config/opencode/claude-acp" --model sonnet --switch-model haiku
node verification/verify.mjs --live --safety --shell-cancellation --plugin "$HOME/.config/opencode/claude-acp" --model sonnet
```

The dotfiles config replaces `opencode-claude-bridge` with `./claude-acp` and
preserves the existing default model and unrelated providers. Source is pinned
to the tested versions; upgrading OpenCode requires repeating these checks.
