# Flutter Agents

`flutter-agents` is a maintained/custom distribution of the Flutter and Dart agent skills from the upstream [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) project. It keeps the upstream skill and Dart MCP integration model while adding a short npm setup command and project-level `AGENTS.md` guidance for automatic task-to-skill routing.

This is not a full-stack workflow. The included skills focus on Flutter and Dart tasks: UI and responsive layouts, routing, localization, serialization, HTTP, architecture, tests, analysis, package conflicts, runtime errors, CLI development, coverage, and FFI.

Use the npm distribution when you want a quick project or global skill installation. Use a native agent plugin when you want the agent's own plugin lifecycle and bundled Dart MCP configuration. This maintained distribution is not an official Google or Flutter product; upstream attribution and the BSD-3-Clause license are preserved.

## Requirements

- Node.js 22.20 or newer for the npm installer.
- Dart 3.9 or newer when using the Dart MCP server.
- One of the supported agents: OpenCode, Codex, Claude Code, Cursor, or Gemini CLI.

## Quick start for a project

Open a terminal at the root of your Flutter or Dart project and run:

```bash
npx flutter-agents@latest
```

This performs two actions:

1. Installs all skills into the current project through the official `skills` CLI for OpenCode, Codex, Claude Code, Cursor, and Gemini CLI.
2. Creates or updates only the managed `flutter-agents` section in the project's `AGENTS.md`.

If you want the official installer directly, without this npm wrapper:

```bash
npx skills add vzwarbee/flutter-agents --skill '*' --agent universal --yes
```

Check the installation:

```bash
npx skills list --json
```

Then give the agent a concrete task, for example: “Fix the RenderFlex overflow on the profile screen.” Compatible agents discover skill metadata first and load the matching skill instructions only when needed.

## Install globally

Install for all five supported agents:

```bash
npx flutter-agents@latest install --global
```

Or choose agents explicitly:

```bash
npx flutter-agents@latest install --global --agent codex,claude-code,cursor,gemini-cli,opencode
```

Global installation makes skills available across projects. It does not create a project `AGENTS.md`; run the following inside each project that needs explicit routing rules:

```bash
npx flutter-agents@latest init
```

## Choose your agent

<details>
<summary><strong>OpenCode</strong></summary>

Project installation:

```bash
npx flutter-agents@latest install --agent opencode
```

Global installation:

```bash
npx flutter-agents@latest install --global --agent opencode
```

OpenCode discovers project skills from `.agents/skills` and global skills from supported user skill directories. Skills are loaded on demand through its native `skill` tool; OpenCode does not use Claude-style slash commands.

Configure the Dart MCP server separately if needed:

```bash
opencode mcp add dart-mcp-server -- dart mcp-server
```

Verify with `npx skills list -a opencode`, then ask OpenCode to list the Flutter/Dart skills relevant to the current task.

</details>

<details>
<summary><strong>Codex</strong></summary>

Fast project installation:

```bash
npx flutter-agents@latest install --agent codex
```

Native plugin installation from this maintained repository:

```bash
codex plugin marketplace add vzwarbee/flutter-agents
codex plugin add dart-flutter@dart-flutter
```

The native plugin bundles skills and `.mcp.json`. Plugin rules cannot currently be bundled automatically, so run `npx flutter-agents@latest init` in the project to add task-routing guidance.

For a manual MCP-only setup:

```bash
codex mcp add dart -- dart mcp-server --force-roots-fallback
```

Verify a skills-CLI installation with `npx skills list -a codex`.

</details>

<details>
<summary><strong>Claude Code</strong></summary>

Fast project installation:

```bash
npx flutter-agents@latest install --agent claude-code
```

Native plugin installation from this maintained repository:

```bash
claude plugin marketplace add vzwarbee/flutter-agents
claude plugin install dart-flutter@dart-flutter
claude plugin marketplace list
```

The native plugin bundles skills and the Dart MCP configuration. Claude Code uses `CLAUDE.md` for persistent project instructions rather than `AGENTS.md`, so reference the generated `AGENTS.md` from your existing Claude project guidance if you need the stronger routing policy there. Skills themselves remain discoverable without a shared slash command.

Manual MCP setup:

```bash
claude mcp add --transport stdio dart -- dart mcp-server
```

Verify a skills-CLI installation with `npx skills list -a claude-code`.

</details>

<details>
<summary><strong>Cursor</strong></summary>

Fast project installation:

```bash
npx flutter-agents@latest install --agent cursor
```

For Cursor's native local-plugin workflow, clone this repository into the local plugin directory and restart Cursor:

```bash
git clone https://github.com/vzwarbee/flutter-agents.git ~/.cursor/plugins/local/dart-flutter
```

The native plugin exposes the repository skills and `.mcp.json`. A manual project MCP configuration can also be placed in `.cursor/mcp.json`.

Verify a skills-CLI installation with `npx skills list -a cursor`, and confirm the skills appear in Cursor after restarting it.

</details>

<details>
<summary><strong>Gemini CLI</strong></summary>

Project installation:

```bash
npx flutter-agents@latest install --agent gemini-cli
```

Global installation:

```bash
npx flutter-agents@latest install --global --agent gemini-cli
```

Gemini CLI uses `.gemini/skills` for project skills and `~/.gemini/skills` for user skills. Check discovery inside Gemini CLI with:

```text
/skills list
```

Gemini uses `GEMINI.md`, not `AGENTS.md`, for persistent project context. Its Dart MCP configuration belongs in project `.gemini/settings.json` or user `~/.gemini/settings.json`. Skill invocation is metadata-driven; do not assume another agent's slash commands are available.

</details>

## Project guidance only

Create or refresh the managed section without reinstalling skills:

```bash
npx flutter-agents@latest init
```

Existing content outside these markers is preserved:

```text
<!-- flutter-agents:start -->
...
<!-- flutter-agents:end -->
```

## Update, inspect, and remove

```bash
# Update this project's installed skills
npx flutter-agents@latest update

# Update globally installed skills
npx flutter-agents@latest update --global

# Inspect project or global installations
npx flutter-agents@latest list
npx flutter-agents@latest list --global

# Use the official interactive removal flow to avoid removing unrelated skills
npx skills remove
npx skills remove --global
```

## Included skills

The repository currently contains 10 Flutter skills and 12 Dart skills.

### Flutter

| Skill | Purpose |
|---|---|
| [`flutter-add-integration-test`](skills/flutter-add-integration-test/SKILL.md) | Add and automate Flutter integration tests. |
| [`flutter-add-widget-preview`](skills/flutter-add-widget-preview/SKILL.md) | Add interactive widget previews. |
| [`flutter-add-widget-test`](skills/flutter-add-widget-test/SKILL.md) | Test widget rendering and interaction. |
| [`flutter-apply-architecture-best-practices`](skills/flutter-apply-architecture-best-practices/SKILL.md) | Structure or explicitly refactor application architecture. |
| [`flutter-build-responsive-layout`](skills/flutter-build-responsive-layout/SKILL.md) | Build adaptive mobile, tablet, desktop, and web layouts. |
| [`flutter-fix-layout-issues`](skills/flutter-fix-layout-issues/SKILL.md) | Diagnose overflows and constraint errors. |
| [`flutter-implement-json-serialization`](skills/flutter-implement-json-serialization/SKILL.md) | Implement JSON model mapping. |
| [`flutter-setup-declarative-routing`](skills/flutter-setup-declarative-routing/SKILL.md) | Configure URL-based routing and deep links. |
| [`flutter-setup-localization`](skills/flutter-setup-localization/SKILL.md) | Configure generated localization. |
| [`flutter-use-http-package`](skills/flutter-use-http-package/SKILL.md) | Implement REST requests with `package:http`. |

### Dart

The synced Dart catalog covers unit tests, test mocks, static analysis, runtime errors, package conflicts, coverage, CLI applications, matcher-to-checks migration, FFI assets and bindings, pattern matching, and primary constructors. See [`skills/dart-*`](skills/) for the generated catalog.

Files under `skills/dart-*` are synchronized from [`dart-lang/skills`](https://github.com/dart-lang/skills). Update them through the repository sync workflow rather than editing them directly.

## Official setup references

- [Flutter: Get started developing with AI](https://docs.flutter.dev/ai/get-started)
- [Flutter and Dart agent skills](https://docs.flutter.dev/ai/agent-skills)
- [Flutter AI rules](https://docs.flutter.dev/ai/ai-rules)
- [Dart and Flutter MCP server](https://docs.flutter.dev/ai/mcp-server)
- [OpenCode skills](https://opencode.ai/docs/skills)
- [Gemini CLI skills](https://geminicli.com/docs/cli/tutorials/skills-getting-started/)
- [`skills` CLI](https://github.com/vercel-labs/skills)

## Upstream and license

This maintained distribution is based on [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins), with Dart skills synchronized from [`dart-lang/skills`](https://github.com/dart-lang/skills). See [LICENSE](LICENSE), [CONTRIBUTING.md](CONTRIBUTING.md), and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
