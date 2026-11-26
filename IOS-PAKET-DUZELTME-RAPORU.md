# RizeDijital iOS kaynak paketi - kontrollü düzeltme raporu

## Yapılan düzenlemeler

- `ios-apple/scripts/verify-ios-version.mjs` artık sabit `mobile-app` yolunu kullanmıyor; gerçek `ios-apple` klasörünü temel alıyor.
- iOS-only `release.json` içindeki eski Android sürüm alanları kaldırıldı; Android/Web sürüm eşitlemesi yok.
- Xcode App + OneSignal NSE `CURRENT_PROJECT_VERSION` 56'ya eşitlendi. **Yayımlanmış önceki sürüm 1.00.18 (55)**; bu yeni paket **1.00.19 (56)** yayın hedefidir.
- Kurulum belgelerindeki eski `mobile-app/` yolları `ios-apple/` olarak değiştirildi.
- Codemagic simülatör testi, sabit iPhone 17/runtıme yerine kullanılabilir simulator modelini seçiyor.
- `GoogleSignIn` 9.0.0 korunmuştur. `configure-ios-google-client.mjs` mevcut canlı public API'den iOS Client ID almayı sürdürüyor. API kapalı/yanlışsa hata vererek durur; gerçek servis erişimi yalnız Codemagic üzerinde doğrulanabilir.
- Podfile OneSignalXCFramework `5.5.5` sürümüne sabitlendi. `Podfile.lock` Mac/CocoaPods üzerinde gerçek `pod install` yapıldığında oluşturulur; burada uydurulmuş kilit dosyası yoktur. Codemagic lockfile'ı artifact olarak saklıyor; deterministik sonraki derleme için onaylanan lockfile'ı Git'e ekleyin.
- `verify:release` ile bundle ID, extension, entitlements, StoreKit kaynakları, pod ve sunucu adresine statik kontroller eklendi.
- Codemagic imzalı IPA iş akışı eski haliyle korunmuştur; Apple sertifikası, *iki ayrı* provisioning profili ve App Group/Sign in with Apple/Push yetkileri Apple Developer ile Codemagic içinde yetkilendirilmelidir.

## Bilinçli olarak değiştirilmedi

AppDelegate.swift, StoreKit iş mantığı, Apple ve Google native giriş, OneSignal eklenti kodu, konum/ses izinleri, canlı web URL'si, ikonlar ve splash görselleri.

## Dış sistemlerde mutlaka test edilmesi gerekenler

1. Codemagic simülatör derlemesi, açılış ve screenshot.
2. Signed IPA / TestFlight: ana uygulama ile OneSignal extension için geçerli provisioning, App Group ve push yetkileri.
3. Google iOS OAuth URL scheme ve canlı API yanıtı; Google giriş callback testi.
4. Apple ile giriş görünürlüğünün sunucudan gelen etkinlik ayarına göre doğru çalışması (web tarafına ayrıca bakılmalıdır).
5. App Store Connect ürün kimlikleriyle StoreKit Sandbox satın alma, geri yükleme, sunucu fiş/işlem doğrulama.
6. Gerçek cihazdan OneSignal/APNs push iletimi ve konum izinleri.

**Bu ortamda macOS/Xcode, Apple Developer hesabı ve test satın alma işlemleri yoktur. Tam IPA oluşturulup cihazda çalıştığı iddia edilmez.**

## Yeni sürüm bilgisi

- App Store’da aktif eski sürüm: **1.00.18 (55)**.
- Yeni IPA hedefi: **1.00.19 (56)**.
- `release.json`, iki Info.plist, Xcode App ve NSE ayarları, Capacitor User-Agent ve npm sürümü eşitlendi.
- Birim doğrulamaları kaynak düzeyindedir; gerçek Xcode derlemesi ve App Store Connect üzerinde 56 build kullanılabilirliği kontrol edilmelidir.
