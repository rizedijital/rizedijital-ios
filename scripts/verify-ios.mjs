import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const required = [
  'capacitor.config.ts',
  'package.json',
  'package-lock.json',
  'ios/App/Podfile',
  'ios/App/App/Info.plist',
  'ios/App/App/AppDelegate.swift',
  'ios/App/App/App.entitlements',
  'ios/App/App/PrivacyInfo.xcprivacy',
  'ios/App/App.xcodeproj/project.pbxproj',
  'ios/App/OneSignalNotificationServiceExtension/Info.plist',
  'ios/App/OneSignalNotificationServiceExtension/NotificationService.swift',
  'www/offline.html',
];
const missing = required.filter((item) => !fs.existsSync(path.join(root, item)));
if (missing.length) {
  console.error('Eksik iOS kaynakları:', missing.join(', '));
  process.exit(1);
}
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
for (const [name, version] of Object.entries({
  '@capacitor/core': '8.4.2',
  '@capacitor/ios': '8.4.2',
  '@capacitor/cli': '8.4.2',
  '@onesignal/capacitor-plugin': '1.1.5',
})) {
  if ((pkg.dependencies?.[name] ?? pkg.devDependencies?.[name]) !== version) {
    console.error(`Sürüm uyuşmazlığı: ${name}`);
    process.exit(1);
  }
}
const config = fs.readFileSync(path.join(root, 'capacitor.config.ts'), 'utf8');
if (!config.includes("appId: 'com.rizedijital.app'") ||
    !config.includes("url: 'https://rizedijital.com'")) {
  console.error('Bundle ID veya canlı web adresi beklenen değerle eşleşmiyor.');
  process.exit(1);
}
console.log('iOS kaynak kontrolü başarılı. Bu kontrol Apple imzalama/IAP veya canlı servis testinin yerine geçmez.');
