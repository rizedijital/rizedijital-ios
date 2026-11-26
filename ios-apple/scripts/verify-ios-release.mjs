import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const app = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const mustRead = rel => fs.readFileSync(path.join(app, rel), 'utf8');
const pbx = mustRead('ios/App/App.xcodeproj/project.pbxproj');
const entApp = mustRead('ios/App/App/App.entitlements');
const entNse = mustRead('ios/App/OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements');
const swift = mustRead('ios/App/App/AppDelegate.swift');
const pod = mustRead('ios/App/Podfile');
const config = mustRead('capacitor.config.ts');
const info = mustRead('ios/App/App/Info.plist');
const tests = [
  ['Apple 90683 konum kullanımı açıklaması', /<key>NSLocationAlwaysAndWhenInUseUsageDescription<\/key>\s*<string>[^<]+<\/string>/.test(info)],
  ['Ön plan konum açıklaması', /<key>NSLocationWhenInUseUsageDescription<\/key>\s*<string>[^<]+<\/string>/.test(info)],
  ['iOS app bundle ID', pbx.includes('PRODUCT_BUNDLE_IDENTIFIER = com.rizedijital.app;')],
  ['OneSignal extension bundle ID', pbx.includes('PRODUCT_BUNDLE_IDENTIFIER = com.rizedijital.app.OneSignalNotificationServiceExtension;')],
  ['App / NSE signing entitlements', pbx.includes('App/App.entitlements') && pbx.includes('OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements')],
  ['Matching OneSignal app group', entApp.includes('group.com.rizedijital.app.onesignal') && entNse.includes('group.com.rizedijital.app.onesignal')],
  ['Apple sign-in entitlement', entApp.includes('com.apple.developer.applesignin')],
  ['Push entitlement', entApp.includes('aps-environment')],
  ['StoreKit purchase and restore entry points', ['import StoreKit', 'Product.products(for:', 'Transaction.currentEntitlements', 'AppStore.sync()'].every(v => swift.includes(v))],
  ['GoogleSignIn pod', pod.includes("pod 'GoogleSignIn', '9.0.0'")],
  ['OneSignal extension pod pinned', pod.includes("pod 'OneSignalXCFramework', '5.5.5'")],
  ['HTTPS remote web', config.includes("url: 'https://rizedijital.com'")],
];
let errors = 0;
for (const [label, ok] of tests) { console.log((ok?'OK':'FAIL') + ': ' + label); if(!ok) errors++; }
console.log('NOTE: Static checks cannot verify Apple provisioning, OAuth live service, APNs delivery or StoreKit sandbox.');
if (errors) process.exit(1);
