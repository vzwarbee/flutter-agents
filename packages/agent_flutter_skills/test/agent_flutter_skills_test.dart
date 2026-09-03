import 'dart:io';

import 'package:agent_flutter_skills/agent_flutter_skills.dart';
import 'package:test/test.dart';

void main() {
  group('parseArgs', () {
    test('defaults to project setup for every supported agent', () {
      final options = parseArgs(const []);

      expect(options.command, CliCommand.setup);
      expect(options.global, isFalse);
      expect(options.writeAgents, isTrue);
      expect(options.agents, supportedAgents);
    });

    test('parses a global installation for selected agents', () {
      final options = parseArgs(const [
        'install',
        '--global',
        '--agent',
        'codex,claude-code',
      ]);

      expect(options.command, CliCommand.install);
      expect(options.global, isTrue);
      expect(options.writeAgents, isFalse);
      expect(options.agents, const ['codex', 'claude-code']);
    });

    test('rejects unsupported agents', () {
      expect(
        () => parseArgs(const ['install', '--agent', 'unknown']),
        throwsFormatException,
      );
    });
  });

  group('updateAgentsDocument', () {
    test('updates only the managed block', () {
      const original = '# Team rules\n\nKeep this text.\n';
      final first = updateAgentsDocument(original, 'First managed rules.');
      final second = updateAgentsDocument(first, 'Updated managed rules.');

      expect(second, contains('Keep this text.'));
      expect(second, contains('Updated managed rules.'));
      expect(second, isNot(contains('First managed rules.')));
      expect('<!-- flutter-agents:start -->'.allMatches(second).length, 1);
    });

    test('rejects unbalanced managed markers', () {
      expect(
        () => updateAgentsDocument(
          '<!-- flutter-agents:start -->\nbroken',
          'rules',
        ),
        throwsFormatException,
      );
    });
  });

  group('installDistribution', () {
    late Directory projectDirectory;
    late Directory homeDirectory;

    setUp(() {
      projectDirectory = Directory.systemTemp.createTempSync(
        'agent_flutter_skills_project_',
      );
      homeDirectory = Directory.systemTemp.createTempSync(
        'agent_flutter_skills_home_',
      );
    });

    tearDown(() {
      projectDirectory.deleteSync(recursive: true);
      homeDirectory.deleteSync(recursive: true);
    });

    test('installs project skills and managed guidance', () async {
      final options = parseArgs(const []);

      await installDistribution(
        options,
        workingDirectory: projectDirectory,
        homeDirectory: homeDirectory,
        environment: const {},
        files: const {
          'skills/example/SKILL.md': '# Example skill\n',
          'templates/AGENTS.md': 'Use matching skills.\n',
        },
      );

      expect(
        File(
          '${projectDirectory.path}/.agents/skills/example/SKILL.md',
        ).readAsStringSync(),
        '# Example skill\n',
      );
      expect(
        File(
          '${projectDirectory.path}/.claude/skills/example/SKILL.md',
        ).readAsStringSync(),
        '# Example skill\n',
      );
      expect(
        File('${projectDirectory.path}/AGENTS.md').readAsStringSync(),
        contains('Use matching skills.'),
      );
    });

    test('project install does not require a home environment', () async {
      await installDistribution(
        parseArgs(const ['install', '--agent', 'codex']),
        workingDirectory: projectDirectory,
        environment: const {},
        files: const {
          'skills/example/SKILL.md': '# Example skill\n',
          'templates/AGENTS.md': 'Use matching skills.\n',
        },
      );

      expect(
        File(
          '${projectDirectory.path}/.agents/skills/example/SKILL.md',
        ).existsSync(),
        isTrue,
      );
    });

    test('dry run does not write files', () async {
      final options = parseArgs(const ['install', '--dry-run']);

      final actions = await installDistribution(
        options,
        workingDirectory: projectDirectory,
        homeDirectory: homeDirectory,
        environment: const {},
        files: const {
          'skills/example/SKILL.md': '# Example skill\n',
          'templates/AGENTS.md': 'Use matching skills.\n',
        },
      );

      expect(actions, isNotEmpty);
      expect(
        Directory('${projectDirectory.path}/.agents').existsSync(),
        isFalse,
      );
      expect(File('${projectDirectory.path}/AGENTS.md').existsSync(), isFalse);
    });

    test('lists a skill once when multiple agents share it', () async {
      final options = parseArgs(const [
        'install',
        '--agent',
        'codex,claude-code',
      ]);
      await installDistribution(
        options,
        workingDirectory: projectDirectory,
        homeDirectory: homeDirectory,
        environment: const {},
        files: const {
          'skills/example/SKILL.md': '# Example skill\n',
          'templates/AGENTS.md': 'Use matching skills.\n',
        },
      );

      final installed = await listDistribution(
        parseArgs(const ['list', '--agent', 'codex,claude-code']),
        workingDirectory: projectDirectory,
        homeDirectory: homeDirectory,
        environment: const {},
      );

      expect(installed, const ['example']);
    });

    test(
      'uses agent-specific global directories and environment overrides',
      () async {
        final options = parseArgs(const [
          'install',
          '--global',
          '--agent',
          'opencode,codex',
        ]);
        final configDirectory = Directory(
          '${homeDirectory.path}/custom-config',
        );
        final codexDirectory = Directory('${homeDirectory.path}/custom-codex');

        await installDistribution(
          options,
          workingDirectory: projectDirectory,
          homeDirectory: homeDirectory,
          environment: {
            'XDG_CONFIG_HOME': configDirectory.path,
            'CODEX_HOME': codexDirectory.path,
          },
          files: const {
            'skills/example/SKILL.md': '# Example skill\n',
            'templates/AGENTS.md': 'Use matching skills.\n',
          },
        );

        expect(
          File(
            '${configDirectory.path}/opencode/skills/example/SKILL.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          File('${codexDirectory.path}/skills/example/SKILL.md').existsSync(),
          isTrue,
        );
        expect(
          File('${projectDirectory.path}/AGENTS.md').existsSync(),
          isFalse,
        );
      },
    );

    test('init updates guidance without installing skills', () async {
      await installDistribution(
        parseArgs(const ['init']),
        workingDirectory: projectDirectory,
        homeDirectory: homeDirectory,
        environment: const {},
        files: const {
          'skills/example/SKILL.md': '# Example skill\n',
          'templates/AGENTS.md': 'Use matching skills.\n',
        },
      );

      expect(File('${projectDirectory.path}/AGENTS.md').existsSync(), isTrue);
      expect(
        Directory('${projectDirectory.path}/.agents').existsSync(),
        isFalse,
      );
      expect(
        Directory('${projectDirectory.path}/.claude').existsSync(),
        isFalse,
      );
    });
  });
}
