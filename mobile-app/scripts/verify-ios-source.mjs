import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve(import.meta.dirname, '..');
const required = [
 'ios/App/Podfile', 'ios/App/App.xcworkspace/contents.xcworkspacedata',
 'ios/App/App.xcodeproj/project.pbxproj', 'ios/App/App/AppDelegate.swift',
 'ios/App/App/Info.plist', 'ios/App/App/App.entitlements',
 'ios/App/OneSignalNotificationServiceExtension/NotificationService.swift',
 'ios/App/OneSignalNotificationServiceExtension/Info.plist',
 'ios/App/App/Assets.xcassets/AppIcon.appiconset/Contents.json',
 'ios/App/App/Base.lproj/Main.storyboard', 'ios/App/App/Base.lproj/LaunchScreen.storyboard',
 'capacitor.config.ts', 'package-lock.json', 'www/index.html', 'www/offline.html'
];
let failed = false;
for (const rel of required) if (!fs.existsSync(path.join(root,rel))) {
 console.error(`EKSİK: ${rel}`); failed = true;
}
const swift = fs.readFileSync(path.join(root,'ios/App/App/AppDelegate.swift'),'utf8');
for (const s of ['import StoreKit','Product.products(for:', 'Transaction.currentEntitlements',
 'AppStore.sync()', 'RizeDijitalNativePaymentsPlugin', 'RizeDijitalSocialAuthPlugin',
 'RizeDijitalLocationPermissionPlugin', 'RizeDijitalPushPermissionPlugin']) {
 if (!swift.includes(s)) { console.error(`iOS özelliği eksik: ${s}`);failed=true; }
}
const pods = fs.readFileSync(path.join(root,'ios/App/Podfile'),'utf8');
for (const s of ['OnesignalCapacitorPlugin','CapacitorCommunitySpeechRecognition','GoogleSignIn','OneSignalNotificationServiceExtension']) {
 if(!pods.includes(s)) {console.error(`iOS Pod eksik: ${s}`);failed=true;}
}
const info = fs.readFileSync(path.join(root,'ios/App/App/Info.plist'),'utf8');
const release = JSON.parse(fs.readFileSync(path.resolve(root, '../release.json'), 'utf8'));
const version = String(release.iosVersion || release.version);
const build = String(release.iosBuild);
if (!info.includes(`<string>${version}</string>`) || !info.includes(`<string>${build}</string>`)) {
 console.error(`iOS ${version} / build ${build} Info.plist sürümü eşleşmiyor.`); failed = true;
}
const nseInfo = fs.readFileSync(path.join(root,'ios/App/OneSignalNotificationServiceExtension/Info.plist'),'utf8');
if (!nseInfo.includes(`<string>${version}</string>`) || !nseInfo.includes(`<string>${build}</string>`)) {
 console.error('OneSignal extension version/build uyuşmuyor.'); failed = true;
}
const pbx = fs.readFileSync(path.join(root,'ios/App/App.xcodeproj/project.pbxproj'),'utf8');
if (!pbx.includes(`MARKETING_VERSION = ${version}`) || !pbx.includes(`CURRENT_PROJECT_VERSION = ${build}`)) {
 console.error('Xcode app / extension build settings sürüm uyumsuz.'); failed = true;
}
if (failed) process.exit(1);
console.log('RizeDijital iOS kaynak kontrolü başarılı. Apple imzalama, StoreKit testleri ve APNs servis testlerini kapsamaz.');
