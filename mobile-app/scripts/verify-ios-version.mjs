import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve(import.meta.dirname, '../..');
const app = path.join(root, 'mobile-app');
const release = JSON.parse(fs.readFileSync(path.join(root, 'release.json'), 'utf8'));
const version = String(release.version);
const build = String(release.iosBuild);
const read = (rel) => fs.readFileSync(path.join(app, rel), 'utf8');
const plist = read('ios/App/App/Info.plist');
const extension = read('ios/App/OneSignalNotificationServiceExtension/Info.plist');
const pbx = read('ios/App/App.xcodeproj/project.pbxproj');
const config = read('capacitor.config.ts');
const pkg = JSON.parse(read('package.json'));
const checks = [
  ['iOS app surumu', plist.includes(`<string>${version}</string>`) && plist.includes(`<string>${build}</string>`)],
  ['OneSignal extension surumu', extension.includes(`<string>${version}</string>`) && extension.includes(`<string>${build}</string>`)],
  ['Xcode surumu', pbx.includes(`MARKETING_VERSION = ${version}`) && pbx.includes(`CURRENT_PROJECT_VERSION = ${build}`)],
  ['Native User-Agent', config.includes(`RizeDijitalNative/${version}`)],
  ['npm paketi', pkg.version === version.replace(/^0*(\d+)\.0*(\d+)\.0*(\d+)$/, '$1.$2.$3')]
];
let errors = 0;
for (const [label, ok] of checks) {
  console.log(`${ok ? 'OK' : 'HATA'}: ${label}`);
  if (!ok) errors++;
}
if (errors) process.exit(1);
console.log(`iOS surumu ${version}, build ${build}. Android ve web projeleri bu iOS kaynak paketine dahil degildir.`);
