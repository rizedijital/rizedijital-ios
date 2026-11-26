import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const appRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const projectRoot = path.resolve(appRoot, '..');
const desired = Number(process.argv[2]);
if (!Number.isSafeInteger(desired) || desired < 1) {
  console.error('Kullanım: node scripts/set-ios-build-number.mjs <pozitif-tamsayi>');
  process.exit(1);
}
const releaseFile = path.join(projectRoot, 'release.json');
const release = JSON.parse(fs.readFileSync(releaseFile, 'utf8'));
const sourceBuild = Number(release.iosBuild);
if (!Number.isSafeInteger(sourceBuild) || sourceBuild < 1) throw Error('release.json iosBuild geçersiz');
if (desired < sourceBuild) throw Error(`Derleme numarası azaltılamaz: ${sourceBuild} -> ${desired}`);
const plistFiles = [
  'ios/App/App/Info.plist',
  'ios/App/OneSignalNotificationServiceExtension/Info.plist',
];
const edits = [];
for (const rel of plistFiles) {
  const file = path.join(appRoot, rel);
  const before = fs.readFileSync(file, 'utf8');
  const pattern = /(<key>CFBundleVersion<\/key>\s*<string>)(\d+)(<\/string>)/g;
  const matches = [...before.matchAll(pattern)];
  if (matches.length !== 1 || Number(matches[0][2]) !== sourceBuild) throw Error(`${rel}: CFBundleVersion beklenmedik`);
  edits.push([file, before.replace(pattern, (_match, left, _old, right) => `${left}${desired}${right}`)]);
}
const projectFile = path.join(appRoot, 'ios/App/App.xcodeproj/project.pbxproj');
const pbx = fs.readFileSync(projectFile, 'utf8');
const pattern = /CURRENT_PROJECT_VERSION = (\d+);/g;
const matches = [...pbx.matchAll(pattern)];
if (matches.length !== 4 || matches.some(m => Number(m[1]) !== sourceBuild)) throw Error('Xcode App + OneSignal Debug/Release build ayarları eşleşmiyor');
edits.push([projectFile, pbx.replace(pattern, `CURRENT_PROJECT_VERSION = ${desired};`)]);
release.iosBuild = desired;
edits.push([releaseFile, JSON.stringify(release, null, 2) + '\n']);
for (const [file, contents] of edits) fs.writeFileSync(file, contents, 'utf8');
console.log(`iOS uygulama + OneSignal uzantısı + Xcode + release.json: build ${desired}`);
