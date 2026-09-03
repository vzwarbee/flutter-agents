import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const output = join(
  root,
  'packages',
  'agent_flutter_skills',
  'lib',
  'src',
  'bundled_files.dart',
);
const inputs = [join(root, 'skills'), join(root, 'templates', 'AGENTS.md')];

function collect(path) {
  const entries = readdirSync(path, { withFileTypes: true }).filter(
    (entry) => !entry.name.startsWith('._') && entry.name !== '.DS_Store',
  );
  return entries.flatMap((entry) => {
    const child = join(path, entry.name);
    return entry.isDirectory() ? collect(child) : [child];
  });
}

const files = inputs.flatMap((input) =>
  input.endsWith('.md') ? [input] : collect(input),
);
files.sort();

const entries = files.map((path) => {
  const key = relative(root, path).replaceAll('\\', '/');
  const value = JSON.stringify(readFileSync(path, 'utf8')).replaceAll('$', '\\$');
  return `  ${JSON.stringify(key)}: ${value},`;
});

const source = `// GENERATED CODE - DO NOT MODIFY BY HAND.\n` +
  `// Run: npm run generate:dart-assets\n\n` +
  `// dart format off\n` +
  `const bundledFiles = <String, String>{\n${entries.join('\n')}\n};\n` +
  `// dart format on\n`;

if (process.argv.includes('--check')) {
  const existing = readFileSync(output, 'utf8');
  if (existing !== source) {
    throw new Error(
      'Bundled Dart assets are stale. Run npm run generate:dart-assets.',
    );
  }
} else {
  writeFileSync(output, source);
}
