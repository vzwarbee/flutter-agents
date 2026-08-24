export const SUPPORTED_AGENTS = [
  'opencode',
  'codex',
  'claude-code',
  'cursor',
  'gemini-cli',
];

const DEFAULT_AGENTS = [...SUPPORTED_AGENTS];

const COMMANDS = new Set(['setup', 'install', 'init', 'update', 'list', 'help']);
const START_MARKER = '<!-- flutter-agents:start -->';
const END_MARKER = '<!-- flutter-agents:end -->';

export function parseArgs(argv) {
  const args = [...argv];
  let command = 'setup';

  if (args[0] && !args[0].startsWith('-')) {
    command = args.shift();
  }
  if (!COMMANDS.has(command)) {
    throw new Error(`Unknown command: ${command}`);
  }

  const options = {
    command,
    global: false,
    agents: DEFAULT_AGENTS,
    writeAgents: command === 'setup' || command === 'install' || command === 'init',
    dryRun: false,
  };

  while (args.length > 0) {
    const arg = args.shift();
    if (arg === '--global' || arg === '-g') {
      options.global = true;
      options.writeAgents = false;
    } else if (arg === '--agent' || arg === '-a') {
      const values = [];
      while (args[0] && !args[0].startsWith('-')) {
        values.push(...args.shift().split(',').filter(Boolean));
      }
      if (values.length === 0) {
        throw new Error(`${arg} requires at least one agent`);
      }
      options.agents = values;
    } else if (arg === '--no-agents') {
      options.writeAgents = false;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--help' || arg === '-h') {
      options.command = 'help';
      options.writeAgents = false;
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }

  for (const agent of options.agents) {
    if (!SUPPORTED_AGENTS.includes(agent)) {
      throw new Error(
        `Unsupported agent: ${agent}. Supported agents: ${SUPPORTED_AGENTS.join(', ')}`,
      );
    }
  }

  return options;
}

export function buildSkillsArgs(options, source) {
  if (
    options.command === 'setup' ||
    options.command === 'install' ||
    options.command === 'update'
  ) {
    if (!source) throw new Error('A skill package source is required');
    return [
      'add',
      source,
      '--skill',
      '*',
      '--agent',
      ...options.agents,
      ...(options.global ? ['--global'] : []),
      '--copy',
      '--yes',
    ];
  }
  if (options.command === 'list') {
    return ['list', ...(options.global ? ['--global'] : [])];
  }
  return null;
}

export function updateAgentsDocument(existing, managedContent) {
  const managedBlock = `${START_MARKER}\n${managedContent.trim()}\n${END_MARKER}`;
  const start = existing.indexOf(START_MARKER);
  const end = existing.indexOf(END_MARKER);

  if ((start === -1) !== (end === -1) || (start !== -1 && end < start)) {
    throw new Error('AGENTS.md has unbalanced flutter-agents markers');
  }

  if (start !== -1 && end !== -1 && end > start) {
    return `${existing.slice(0, start)}${managedBlock}${existing.slice(end + END_MARKER.length)}`;
  }

  const prefix = existing.length > 0 && !existing.endsWith('\n') ? `${existing}\n` : existing;
  return `${prefix}${prefix.length > 0 ? '\n' : ''}${managedBlock}\n`;
}
