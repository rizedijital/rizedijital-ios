/**
 * RizeDijital 1.00.18 — Google iOS OAuth URL scheme is derived from the public,
 * non-secret Client ID in Admin > Mobil Ayarlar at iOS build time.
 *
 * Normal use (Codemagic): node scripts/configure-ios-google-client.mjs
 * Offline deterministic test: node scripts/configure-ios-google-client.mjs --config-file /path/to/public-config.json
 *
 * No Codemagic environment variable, Google secret, or API key is required.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PUBLIC_CONFIG_URL = 'https://rizedijital.com/api/mobil-yapilandirma?platform=ios';
const PLIST_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../ios/App/App/Info.plist');
const CLIENT_ID_RE = /^([0-9]+-[A-Za-z0-9_-]+)\.apps\.googleusercontent\.com$/;
const REVERSED_RE = /^com\.googleusercontent\.apps\.[0-9]+-[A-Za-z0-9_-]+$/;

function error(message) {
  console.error('HATA: ' + message);
  process.exitCode = 1;
}

async function getConfig() {
  if (process.argv.length > 2) {
    if (process.argv.length !== 4 || process.argv[2] !== '--config-file') {
      throw new Error('Kullanım: node scripts/configure-ios-google-client.mjs [--config-file /path/to/config.json]');
    }
    // Offline test only; Codemagic calls the script without parameters.
    return JSON.parse(fs.readFileSync(path.resolve(process.argv[3]), 'utf8'));
  }

  console.log('Google iOS OAuth Client ID, RizeDijital public mobil API üzerinden okunuyor...');
  let lastError;
  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      const response = await fetch(PUBLIC_CONFIG_URL, {
        headers: { Accept: 'application/json' },
        cache: 'no-store',
        signal: AbortSignal.timeout(15000),
      });
      const destination = new URL(response.url);
      if (destination.protocol !== 'https:' || !['rizedijital.com', 'www.rizedijital.com'].includes(destination.hostname)) {
        throw new Error('Beklenmeyen sunucu adresine yönlendirme: ' + destination.hostname);
      }
      if (!response.ok) throw new Error('Mobil yapılandırma API HTTP ' + response.status);
      return await response.json();
    } catch (caught) {
      lastError = caught;
      if (attempt < 2) await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  throw new Error('Mobil yapılandırma API okunamadı: ' + lastError.message);
}

function applyScheme(config) {
  const social = config?.native_bridge?.social_login;
  const provider = social?.providers?.google;
  if (config?.schema_version !== 1 || social?.platform !== 'ios' || !provider || typeof provider !== 'object') {
    throw new Error('Beklenen iOS sosyal giriş yapılandırması alınamadı. Web v1.00.18 ve ?platform=ios yanıtını kontrol edin.');
  }
  const enabled = provider.native_enabled === true;
  const clientId = String(provider.ios_client_id ?? '').trim();
  if (!clientId) {
    if (enabled) {
      throw new Error('iOS Google girişi açık ama Google iOS OAuth Client ID boş. Admin > Mobil Ayarlar > Native Sosyal Giriş alanını doldurup Kaydet yapın.');
    }
    console.log('iOS Google girişi kapalı ve Client ID boş; Google URL scheme eklenmedi.');
    return;
  }
  const match = clientId.match(CLIENT_ID_RE);
  if (!match) throw new Error('Web panelindeki Google iOS OAuth Client ID geçersiz. Şema eklenmedi.');
  const reversed = 'com.googleusercontent.apps.' + match[1];
  if (!REVERSED_RE.test(reversed)) throw new Error('Google iOS URL scheme geçersiz.');
  const original = fs.readFileSync(PLIST_PATH, 'utf8');
  // Restrict the edit to the first (RizeDijital) CFBundleURLSchemes array only.
  const schemesPattern = /(<key>CFBundleURLSchemes<\/key>\s*<array>)([\s\S]*?)(\s*<\/array>)/;
  const matchScheme = original.match(schemesPattern);
  if (!matchScheme || !/<string>rizedijital<\/string>/.test(matchScheme[2])) {
    throw new Error('iOS Info.plist dosyasında RizeDijital CFBundleURLSchemes alanı bulunamadı; dosya değiştirilmedi.');
  }
  // Remove old Google schemes, retain every unrelated scheme.
  const retained = matchScheme[2].replace(/\s*<string>com\.googleusercontent\.apps\.[A-Za-z0-9_-]+<\/string>/g, '');
  const updatedInner = retained.replace(/\s+$/, '') + '\n\t\t\t\t<string>' + reversed + '</string>';
  const nextBlock = matchScheme[1] + updatedInner + matchScheme[3];
  const next = original.replace(schemesPattern, nextBlock);
  if (!next.includes('<string>' + reversed + '</string>')) throw new Error('Scheme değişikliği doğrulanamadı.');
  if (next !== original) fs.writeFileSync(PLIST_PATH, next, 'utf8');
  console.log('Google iOS URL scheme doğrulandı ve Info.plist dosyasına işlendi: ' + reversed);
  console.log('Kaynak: Admin > Mobil Ayarlar (public mobil yapılandırma). Codemagic ortam değişkeni kullanılmadı.');
}

try { applyScheme(await getConfig()); }
catch (caught) { error(caught.message); }
