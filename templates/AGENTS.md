# Flutter and Dart skill routing

This project uses task-specific Flutter and Dart skills. Treat skills as focused workflows, not as a full-stack framework or a reason to restructure unrelated code.

For every request:

1. Read the available skill names and descriptions before implementation.
2. Load every skill whose description directly matches the task, and follow its instructions before editing code.
3. Prefer existing project architecture, dependencies, naming, design system, and state-management conventions. Do not apply `flutter-apply-architecture-best-practices` unless the task explicitly creates or changes architecture.
4. Use Flutter UI skills for widget, layout, responsive design, preview, localization, routing, serialization, HTTP, and Flutter test tasks. Use Dart skills only for matching Dart analysis, testing, CLI, dependency, runtime, FFI, coverage, or language tasks.
5. Use the Dart and Flutter MCP server when available for analysis, tests, runtime inspection, widget selection, and hot reload.
6. Verify changed Dart and Flutter code with formatting, static analysis, and the smallest relevant tests. Report any verification that could not run.

Do not invoke unrelated skills, invent a full-stack workflow, or migrate architecture solely because a skill exists.
