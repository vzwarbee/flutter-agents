#!/usr/bin/env node

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildSkillsArgs, parseArgs, updateAgentsDocument } from './cli-lib.mjs';

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));

function printHelp() {
  console.log(`flutter-agents

Install Flutter and Dart skills and bootstrap project-level agent guidance.

Usage:
  flutter-agents                         Install in the current project and create AGENTS.md
  flutter-agents install                Same as the default setup
  flutter-agents install --global       Install globally for all supported agents
  flutter-agents install -g -a codex cursor
  flutter-agents init                   Create or update the managed AGENTS.md section only
  flutter-agents update [--global]      Update installed skills
  flutter-agents list [--global]        List installed skills

Options:
  -a, --agent <names>  opencode, codex, claude-code, cursor, gemini-cli
  -g, --global         Use the user-level installation scope
      --no-agents      Do not create or update AGENTS.md
      --dry-run        Print actions without changing files or installing skills
  -h, --help           Show this help
`);
}

function writeAgentsFile({ dryRun }) {
  const target = resolve(process.cwd(), 'AGENTS.md');
  const template = readFileSync(join(packageRoot, 'templates', 'AGENTS.md'), 'utf8');
  const existing = existsSync(target) ? readFileSync(target, 'utf8') : '';
  const updated = updateAgentsDocument(existing, template);

  if (dryRun) {
    console.log(`[dry-run] update ${target}`);
    return;
  }
  writeFileSync(target, updated, 'utf8');
  console.log(`Updated ${target}`);
}

function runSkills(args, { dryRun }) {
  if (!args) return;
  if (dryRun) {
    console.log(`[dry-run] skills ${args.join(' ')}`);
    return;
  }

  const command = process.platform === 'win32' ? 'skills.cmd' : 'skills';
  const result = spawnSync(command, args, { stdio: 'inherit' });
  if (result.error) {
    throw new Error(`Could not run the skills CLI: ${result.error.message}`);
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.command === 'help') {
    printHelp();
    process.exit(0);
  }

  runSkills(buildSkillsArgs(options, packageRoot), options);
  if (options.writeAgents) writeAgentsFile(options);
} catch (error) {
  console.error(`Error: ${error.message}`);
  console.error('Run flutter-agents --help for usage.');
  process.exit(1);
}
