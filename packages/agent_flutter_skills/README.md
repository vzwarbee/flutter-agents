# Flutter Agents

`agent_flutter_skills` installs the maintained Flutter and Dart agent skills from the
[`flutter-agents`](https://github.com/vzwarbee/flutter-agents) distribution.
It is the Dart-native alternative to the npm installer and does not require
Node.js at runtime.

## Install

With Dart 3.10 or newer:

```bash
dart install agent_flutter_skills
```

The legacy global activation flow is also supported:

```bash
dart pub global activate agent_flutter_skills
```

## Use

Install all skills in the current Flutter or Dart project and add managed
skill-routing guidance to `AGENTS.md`:

```bash
afs
```

Choose agents explicitly:

```bash
afs install --agent codex,claude-code
```

Install globally:

```bash
afs install --global
```

Other commands:

```bash
afs init
afs update
afs list
afs --help
```

The installer supports OpenCode, Codex, Claude Code, Cursor, and Gemini CLI.
Project installation preserves all existing `AGENTS.md` content outside the
managed `flutter-agents` markers.

## Distribution model

The Dart and npm packages are generated from the same `skills/` and
`templates/` source directories in the repository. Installing both packages is
unnecessary; choose the distribution that matches the tools already available
in your environment.
