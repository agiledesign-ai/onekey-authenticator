import { execFileSync } from 'node:child_process';
import { existsSync, lstatSync, readFileSync, readdirSync } from 'node:fs';
import { extname, relative, resolve, sep } from 'node:path';
import process from 'node:process';

const root = resolve(import.meta.dirname, '..');
const ignoredDirectories = new Set([
  '.git',
  '.hvigor',
  '.idea',
  '.test',
  'build',
  'node_modules',
  'oh_modules'
]);
const ignoredRootPrefixes = [
  `docs${sep}superpowers${sep}plans${sep}`,
  `docs${sep}superpowers${sep}specs${sep}`,
  `tests${sep}fixtures${sep}`
];
const ignoredRootFiles = new Set([
  `scripts${sep}open-source-audit.mjs`
]);
const binaryExtensions = new Set([
  '.gif', '.jpeg', '.jpg', '.png', '.webp', '.zip'
]);
const forbiddenTrackedExtensions = new Set([
  '.cer', '.jks', '.key', '.p12', '.p7b', '.pem'
]);
const contentRules = [
  {
    name: 'signing-secret',
    pattern: /(?:keyPassword|storePassword)\s*[=:]\s*["'][^"'\s]+["']/
  },
  {
    name: 'client-id-literal',
    pattern: /["']name["']\s*:\s*["']client_id["'][\s\S]{0,160}["']value["']\s*:\s*["']\d{8,}["']/
  },
  {
    name: 'private-bundle-name',
    pattern: /com\.halolion\.authenticator/
  },
  {
    name: 'personal-path',
    pattern: /\/Users\/[^/\s"']+/
  },
  {
    name: 'wearable-feature',
    pattern: /@kit\.WearEngine|SendToWatchPage|wearEngineRemoteAppNameList|securekey-sync:\/\/watch/,
    productionOnly: true
  }
];

function parseTarget() {
  const index = process.argv.indexOf('--path');
  if (index < 0) {
    return root;
  }
  const value = process.argv[index + 1];
  if (!value) {
    throw new Error('--path requires a file or directory');
  }
  return resolve(root, value);
}

function shouldIgnore(path, applyRepositoryExclusions) {
  if (!applyRepositoryExclusions) {
    return false;
  }
  const relativePath = relative(root, path);
  if (relativePath.startsWith('..')) {
    return false;
  }
  if (ignoredRootFiles.has(relativePath)) {
    return true;
  }
  return ignoredRootPrefixes.some((prefix) => relativePath.startsWith(prefix));
}

function collectFiles(path, files, applyRepositoryExclusions) {
  if (shouldIgnore(path, applyRepositoryExclusions)) {
    return;
  }
  const stat = lstatSync(path);
  if (!stat.isDirectory()) {
    files.push(path);
    return;
  }
  for (const name of readdirSync(path)) {
    if (ignoredDirectories.has(name)) {
      continue;
    }
    collectFiles(resolve(path, name), files, applyRepositoryExclusions);
  }
}

function trackedFileViolations() {
  try {
    const output = execFileSync('git', ['ls-files', '-z'], {
      cwd: root,
      encoding: 'utf8'
    });
    return output
      .split('\0')
      .filter(Boolean)
      .filter((path) => forbiddenTrackedExtensions.has(extname(path).toLowerCase()))
      .map((path) => ({ path, rule: 'sensitive-file-type' }));
  } catch {
    return [];
  }
}

function isProductionPath(path) {
  return /^(?:AppScope|entry|otp_core|wear)(?:\/|$)|^build-profile\.json5$/.test(path);
}

function contentViolations(files, scanningRepository) {
  const violations = [];
  for (const path of files) {
    if (binaryExtensions.has(extname(path).toLowerCase())) {
      continue;
    }
    const relativePath = relative(root, path) || '.';
    const content = readFileSync(path, 'utf8');
    for (const rule of contentRules) {
      if (scanningRepository && rule.productionOnly && !isProductionPath(relativePath)) {
        continue;
      }
      if (rule.pattern.test(content)) {
        violations.push({ path: relativePath, rule: rule.name });
      }
    }
  }
  return violations;
}

const target = parseTarget();
if (!existsSync(target)) {
  process.stderr.write(`Audit target does not exist: ${relative(root, target)}\n`);
  process.exit(2);
}

const files = [];
collectFiles(target, files, target === root);
const violations = contentViolations(files, target === root);
if (target === root) {
  violations.push(...trackedFileViolations());
}

if (violations.length > 0) {
  for (const violation of violations) {
    process.stderr.write(`${violation.path}: ${violation.rule}\n`);
  }
  process.exit(1);
}

process.stdout.write(`Open-source audit passed (${files.length} files checked).\n`);
