import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildSkillsArgs,
  parseArgs,
  updateAgentsDocument,
} from '../src/cli-lib.mjs';

test('defaults to project setup for all supported agents', () => {
  const options = parseArgs([]);

  assert.equal(options.command, 'setup');
  assert.equal(options.global, false);
  assert.deepEqual(options.agents, [
    'opencode',
    'codex',
    'claude-code',
    'cursor',
    'gemini-cli',
  ]);
  assert.equal(options.writeAgents, true);
  assert.deepEqual(buildSkillsArgs(options, '/package'), [
    'add',
    '/package',
    '--skill',
    '*',
    '--agent',
    'opencode',
    'codex',
    'claude-code',
    'cursor',
    'gemini-cli',
    '--copy',
    '--yes',
  ]);
});

test('builds a global install for selected agents without writing project rules', () => {
  const options = parseArgs([
    'install',
    '--global',
    '--agent',
    'codex,claude-code,gemini-cli',
  ]);

  assert.equal(options.command, 'install');
  assert.equal(options.global, true);
  assert.equal(options.writeAgents, false);
  assert.deepEqual(buildSkillsArgs(options, '/package'), [
    'add',
    '/package',
    '--skill',
    '*',
    '--agent',
    'codex',
    'claude-code',
    'gemini-cli',
    '--global',
    '--copy',
    '--yes',
  ]);
});

test('updates only this distribution by reinstalling its packaged skills', () => {
  assert.deepEqual(buildSkillsArgs(parseArgs(['update']), '/package'), [
    'add',
    '/package',
    '--skill',
    '*',
    '--agent',
    'opencode',
    'codex',
    'claude-code',
    'cursor',
    'gemini-cli',
    '--copy',
    '--yes',
  ]);
  assert.deepEqual(buildSkillsArgs(parseArgs(['update', '--global']), '/package'), [
    'add',
    '/package',
    '--skill',
    '*',
    '--agent',
    'opencode',
    'codex',
    'claude-code',
    'cursor',
    'gemini-cli',
    '--global',
    '--copy',
    '--yes',
  ]);
});

test('upserts only the managed section in an existing AGENTS.md', () => {
  const original = '# Team rules\n\nKeep this text.\n';
  const managed = 'Use matching Flutter and Dart skills.';
  const first = updateAgentsDocument(original, managed);
  const second = updateAgentsDocument(first, 'Updated managed rules.');

  assert.match(first, /Keep this text\./);
  assert.match(first, /Use matching Flutter and Dart skills\./);
  assert.match(second, /Keep this text\./);
  assert.doesNotMatch(second, /Use matching Flutter and Dart skills\./);
  assert.equal(second.match(/<!-- flutter-agents:start -->/g)?.length, 1);
});

test('rejects unsupported commands and agents', () => {
  assert.throws(() => parseArgs(['publish']), /Unknown command/);
  assert.throws(
    () => parseArgs(['install', '--agent', 'unknown-agent']),
    /Unsupported agent/,
  );
});

test('rejects an AGENTS.md with unbalanced managed markers', () => {
  assert.throws(
    () => updateAgentsDocument('<!-- flutter-agents:start -->\nbroken', 'rules'),
    /unbalanced flutter-agents markers/,
  );
});
