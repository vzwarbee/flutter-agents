import 'dart:io';

import 'bundled_files.dart';

const supportedAgents = [
  'opencode',
  'codex',
  'claude-code',
  'cursor',
  'gemini-cli',
];

const _startMarker = '<!-- flutter-agents:start -->';
const _endMarker = '<!-- flutter-agents:end -->';

enum CliCommand { setup, install, init, update, list, help }

class CliOptions {
  const CliOptions({
    required this.command,
    required this.global,
    required this.agents,
    required this.writeAgents,
    required this.dryRun,
  });

  final CliCommand command;
  final bool global;
  final List<String> agents;
  final bool writeAgents;
  final bool dryRun;
}

CliOptions parseArgs(List<String> argv) {
  final args = [...argv];
  var command = CliCommand.setup;

  if (args.isNotEmpty && !args.first.startsWith('-')) {
    final commandName = args.removeAt(0);
    command = CliCommand.values.firstWhere(
      (value) => value.name == commandName,
      orElse: () => throw FormatException('Unknown command: $commandName'),
    );
  }

  var global = false;
  var agents = [...supportedAgents];
  var writeAgents = switch (command) {
    CliCommand.setup || CliCommand.install || CliCommand.init => true,
    _ => false,
  };
  var dryRun = false;

  while (args.isNotEmpty) {
    final arg = args.removeAt(0);
    switch (arg) {
      case '--global' || '-g':
        global = true;
        writeAgents = false;
      case '--agent' || '-a':
        final values = <String>[];
        while (args.isNotEmpty && !args.first.startsWith('-')) {
          values.addAll(
            args.removeAt(0).split(',').where((value) => value.isNotEmpty),
          );
        }
        if (values.isEmpty) {
          throw FormatException('$arg requires at least one agent');
        }
        agents = values;
      case '--no-agents':
        writeAgents = false;
      case '--dry-run':
        dryRun = true;
      case '--help' || '-h':
        command = CliCommand.help;
        writeAgents = false;
      default:
        throw FormatException('Unknown option: $arg');
    }
  }

  for (final agent in agents) {
    if (!supportedAgents.contains(agent)) {
      throw FormatException(
        'Unsupported agent: $agent. Supported agents: '
        '${supportedAgents.join(', ')}',
      );
    }
  }

  return CliOptions(
    command: command,
    global: global,
    agents: List.unmodifiable(agents),
    writeAgents: writeAgents,
    dryRun: dryRun,
  );
}

String updateAgentsDocument(String existing, String managedContent) {
  final managedBlock = '$_startMarker\n${managedContent.trim()}\n$_endMarker';
  final start = existing.indexOf(_startMarker);
  final end = existing.indexOf(_endMarker);

  if ((start == -1) != (end == -1) || (start != -1 && end < start)) {
    throw const FormatException(
      'AGENTS.md has unbalanced flutter-agents markers',
    );
  }

  if (start != -1) {
    return '${existing.substring(0, start)}$managedBlock'
        '${existing.substring(end + _endMarker.length)}';
  }

  final prefix = existing.isNotEmpty && !existing.endsWith('\n')
      ? '$existing\n'
      : existing;
  return '$prefix${prefix.isNotEmpty ? '\n' : ''}$managedBlock\n';
}

Future<List<String>> installDistribution(
  CliOptions options, {
  Directory? workingDirectory,
  Directory? homeDirectory,
  Map<String, String>? environment,
  Map<String, String> files = bundledFiles,
}) async {
  final workingDir = workingDirectory ?? Directory.current;
  final env = environment ?? Platform.environment;
  final actions = <String>[];

  if (options.command != CliCommand.init) {
    final destinations = options.agents
        .map(
          (agent) => options.global
              ? _globalSkillsDirectory(
                  agent,
                  homeDirectory ?? Directory(_requiredHome(env)),
                  env,
                )
              : _join(workingDir.path, _projectSkillsDirectory(agent)),
        )
        .toSet();
    final skillFiles = files.entries.where(
      (entry) => entry.key.startsWith('skills/'),
    );

    for (final destination in destinations) {
      for (final source in skillFiles) {
        final relativePath = source.key.substring('skills/'.length);
        final target = File(_join(destination, relativePath));
        actions.add(
          '${options.dryRun ? '[dry-run] ' : ''}write ${target.path}',
        );
        if (!options.dryRun) {
          await target.parent.create(recursive: true);
          await target.writeAsString(source.value);
        }
      }
    }
  }

  if (options.writeAgents) {
    final template = files['templates/AGENTS.md'];
    if (template == null) {
      throw const FormatException(
        'The distribution does not contain templates/AGENTS.md',
      );
    }
    final target = File(_join(workingDir.path, 'AGENTS.md'));
    final existing = await target.exists() ? await target.readAsString() : '';
    final updated = updateAgentsDocument(existing, template);
    actions.add('${options.dryRun ? '[dry-run] ' : ''}update ${target.path}');
    if (!options.dryRun) {
      await target.writeAsString(updated);
    }
  }

  return actions;
}

Future<List<String>> listDistribution(
  CliOptions options, {
  Directory? workingDirectory,
  Directory? homeDirectory,
  Map<String, String>? environment,
}) async {
  final workingDir = workingDirectory ?? Directory.current;
  final env = environment ?? Platform.environment;
  final installedSkills = <String>{};
  final visited = <String>{};

  for (final agent in options.agents) {
    final path = options.global
        ? _globalSkillsDirectory(
            agent,
            homeDirectory ?? Directory(_requiredHome(env)),
            env,
          )
        : _join(workingDir.path, _projectSkillsDirectory(agent));
    if (!visited.add(path)) continue;

    final directory = Directory(path);
    if (!await directory.exists()) continue;
    await for (final entity in directory.list()) {
      if (entity is Directory &&
          await File(_join(entity.path, 'SKILL.md')).exists()) {
        installedSkills.add(entity.path.split(Platform.pathSeparator).last);
      }
    }
  }

  final results = installedSkills.toList()..sort();
  return results;
}

Future<int> runAgentFlutterSkills(
  List<String> arguments, {
  void Function(String message)? printLine,
}) async {
  final output = printLine ?? stdout.writeln;
  try {
    final options = parseArgs(arguments);
    if (options.command == CliCommand.help) {
      output(cliHelp);
      return 0;
    }
    if (options.command == CliCommand.list) {
      final skills = await listDistribution(options);
      if (skills.isEmpty) {
        output('No installed Flutter or Dart skills found.');
      } else {
        for (final skill in skills) {
          output(skill);
        }
      }
      return 0;
    }

    final actions = await installDistribution(options);
    for (final action in actions) {
      output(action);
    }
    return 0;
  } on FormatException catch (error) {
    stderr.writeln('Error: ${error.message}');
    stderr.writeln('Run afs --help for usage.');
    return 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Error: ${error.message}');
    return 1;
  }
}

const cliHelp = '''afs

Install Flutter and Dart skills and bootstrap project-level agent guidance.

Usage:
  afs                         Install in the current project and create AGENTS.md
  afs install                 Same as the default setup
  afs install --global        Install globally for all supported agents
  afs install -g -a codex cursor
  afs init                    Create or update the managed AGENTS.md section only
  afs update [--global]       Update installed skills
  afs list [--global]         List installed skills

Options:
  -a, --agent <names>  opencode, codex, claude-code, cursor, gemini-cli
  -g, --global         Use the user-level installation scope
      --no-agents      Do not create or update AGENTS.md
      --dry-run        Print actions without changing files
  -h, --help           Show this help
''';

String _projectSkillsDirectory(String agent) =>
    agent == 'claude-code' ? '.claude/skills' : '.agents/skills';

String _globalSkillsDirectory(
  String agent,
  Directory home,
  Map<String, String> environment,
) {
  return switch (agent) {
    'opencode' => _join(
      environment['XDG_CONFIG_HOME'] ?? _join(home.path, '.config'),
      'opencode/skills',
    ),
    'codex' => _join(
      environment['CODEX_HOME'] ?? _join(home.path, '.codex'),
      'skills',
    ),
    'claude-code' => _join(
      environment['CLAUDE_CONFIG_DIR'] ?? _join(home.path, '.claude'),
      'skills',
    ),
    'cursor' => _join(home.path, '.cursor/skills'),
    'gemini-cli' => _join(home.path, '.gemini/skills'),
    _ => throw FormatException('Unsupported agent: $agent'),
  };
}

String _requiredHome(Map<String, String> environment) {
  final home = Platform.isWindows
      ? environment['USERPROFILE']
      : environment['HOME'];
  if (home == null || home.isEmpty) {
    throw const FormatException('Could not determine the user home directory');
  }
  return home;
}

String _join(String first, String second) {
  final separator = Platform.pathSeparator;
  final normalizedSecond = second.replaceAll(RegExp(r'[/\\]'), separator);
  if (first.endsWith('/') || first.endsWith('\\')) {
    return '$first$normalizedSecond';
  }
  return '$first$separator$normalizedSecond';
}
