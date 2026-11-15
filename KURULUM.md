# RizeDijital v1.00.18 (55) — Google iOS URL Scheme merkezi yapılandırması

## Hedef
Codemagic artık Google iOS URL Scheme için `RD_IOS_GOOGLE_REVERSED_CLIENT_ID` veya `ios_config` grubunu gerektirmez. Google iOS OAuth Client ID, web yönetim panelinde Admin > Mobil Ayarlar > Native Sosyal Giriş alanında saklanır. iOS derlemesi web sitesinin **public** `/api/mobil-yapilandirma?platform=ios` JSON yanıtındaki `native_bridge.social_login.providers.google.ios_client_id` değerini okur, `com.googleusercontent.apps....` biçimine çevirir ve `mobile-app/ios/App/App/Info.plist` içindeki CFBundleURLSchemes listesine ekler.

## GitHub yükleme
`rizedijital-ios` deposunun köküne yalnızca aşağıdaki iki dosyayı, aynı yolları koruyarak yükleyip mevcut dosyaların üzerine yazın:

- `codemagic.yaml`
- `mobile-app/scripts/configure-ios-google-client.mjs`

iOS'un diğer dosyaları değiştirilmez. Web paneli açıklaması istenirse ayrı Web ZIP'indeki `app/views/admin/mobil-ayarlari.php` dosyası sunucuya yüklenebilir; bu, yalnız açıklamayı değiştirir, toggle görünümlerini korur.

## Codemagic
1. Web panelinden Google iOS OAuth Client ID değerini girip kaydedin. Google iOS anahtarı açıksa boş bırakılamaz.
2. GitHub `main` dalına iki dosyayı commit edin.
3. Codemagic > `rizedijital-ios` > Start new build > Workflow: `rizedijital-ios-simulator`.
4. `Synchronize Capacitor iOS` logunda `Google iOS URL scheme doğrulandı` satırını arayın.
5. `Test iOS Simulator startup` adımında INSTALL, LAUNCH ve SCREENSHOT kontrollerini takip edin.
6. Codemagic'in oluşturduğu yeni `App.app.zip` dosyasını Appetize'e yükleyerek tekrar test edin.

## Notlar
- Web panelinden Google Client ID sonradan değişirse yeni iOS derlemesi gerekir; sadece Google giriş Aç/Kapat değişikliği için gerekmez.
- Apple ile giriş bu Google ayarından **bağımsızdır**; Apple Developer imzası/Sign in with Apple ayrı konudur.
- Sunucunun `https://rizedijital.com/api/mobil-yapilandirma?platform=ios` adresi derleme sırasında erişilebilir olmalıdır. HTTP/JSON/config hatalarında işlem açık ve anlaşılır hata ile durur; hatalı veya eski URL scheme kullanılarak sessizce derleme yapılmaz.
- Public JSON'da sadece OAuth Client ID kullanılır. Google client secret, Apple private key veya Apple/Google ödeme kimlik bilgileri okunmaz.
- Bu kaynak yaması v1.00.18 (iOS build 55) sürümünü değiştirmez. Android, Premium ödeme ve OneSignal native kodu değiştirilmedi.
- Derleme ve gerçek Google ile giriş sonucu Codemagic/Appetize üzerinde test edilmelidir; buradaki yerel kontroller macOS/Xcode veya Google OAuth servis testi değildir.
