import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const required = [
  'node_modules/@capacitor/ios/Capacitor/Capacitor',
  'node_modules/@capacitor/cli/bin/capacitor',
  'ios/App/Podfile',
  'ios/App/App.xcodeproj/project.pbxproj',
];
const missing = required.filter((item) => !fs.existsSync(path.join(root, item)));
if (missing.length) {
  console.error('iOS kurulumunda eksik dosyalar:', missing.join(', '));
  process.exit(1);
}
console.log('RizeDijital iOS bağımlılıkları hazır. Android Gradle adımı çalıştırılmadı.');
