import fs from 'node:fs';
import path from 'node:path';
// App Store/TestFlight derlemesinden önce RD_IOS_GOOGLE_REVERSED_CLIENT_ID ortam değişkenini kullanın.
// Örnek: com.googleusercontent.apps.123456789-abcdef (Google Cloud OAuth iOS istemcisi).
const value = (process.env.RD_IOS_GOOGLE_REVERSED_CLIENT_ID || '').trim();
if (!value) { console.log('Google iOS ters istemci URL şeması verilmedi; mevcut Info.plist korundu.');process.exit(0); }
if (!/^com\.googleusercontent\.apps\.[a-zA-Z0-9_-]+$/.test(value)) {
 console.error('RD_IOS_GOOGLE_REVERSED_CLIENT_ID beklenen biçimde değil.');process.exit(1);
}
const file=path.resolve(import.meta.dirname,'../ios/App/App/Info.plist');
let contents=fs.readFileSync(file,'utf8');
if (contents.includes(`<string>${value}</string>`)) { console.log('Google iOS URL şeması zaten mevcut.');process.exit(0); }
const needle='<string>rizedijital</string>';
if (!contents.includes(needle)) throw Error('Info.plist içinde rizedijital URL şeması bulunamadı.');
contents=contents.replace(needle,needle+`\n                <string>${value}</string>`);
fs.writeFileSync(file,contents);
console.log('Google iOS URL şeması Info.plist dosyasına eklendi.');
