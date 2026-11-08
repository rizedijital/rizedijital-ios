# RizeDijital iOS — iOS-only kaynak paketi

Bu paket, `mobile-app.zip` içindeki iOS uygulama kaynakları ve iOS derlemesi için gereken ortak Capacitor dosyalarından ayrılmıştır. Android proje klasörü bu ZIP'e alınmamıştır.

## Mevcut yapı

- Capacitor 8.4.2
- Bundle ID: `com.rizedijital.app`
- WebView kaynağı: `https://rizedijital.com`
- iOS minimum hedefi: iOS 15.0
- App target + OneSignal Notification Service Extension
- Apple Sign In için native Swift köprüsü mevcut
- Google Sign-In iOS SDK ve native köprü mevcut
- Apple In-App Purchase henüz uygulanmamıştır; native ödeme köprüsü şu anda güvenli `NOT_CONFIGURED` stub döndürür.
- iOS App Store / gerçek cihaz dağıtımı için Apple Developer hesabı, sertifika ve provisioning profile gerekir.

## Gereksinimler

- Node.js 22+
- npm 10+
- macOS üzerinde Xcode 26+ ve CocoaPods (yerel derleme için)
- Bulut derleme için Appcircle veya Codemagic hesabı

## Yerel veya bulut derleme

1. Depo kökünde `npm ci` çalıştırın. iOS-only postinstall, Android Gradle Wrapper işlemi çalıştırmaz.
2. `npm run verify:ios` çalıştırın.
3. `npx cap sync ios` çalıştırın.
4. macOS üzerinde `npx cap open ios` ile Xcode projesini açın.
5. Xcode'da `App` scheme'ini seçin.
6. Simülatör için iPhone Simulator hedefi seçip Debug/Run veya `Xcodebuild for iOS Simulator` kullanın.
7. Gerçek iPhone, TestFlight veya App Store için Apple Developer hesabı, Team ID, imzalama sertifikası ve provisioning profile yapılandırın.

## Appcircle önerilen workflow

- GitHub repository root bu paketin içeriği olmalı.
- Node.js 22 ve npm 10 kullanın.
- Custom Script (Bash) adımında `npm ci` çalıştırın.
- CocoaPods Install adımını çalıştırın.
- Simülatör denemesi için `Xcodebuild for iOS Simulator` adımını kullanın.
- Gerçek cihaz IPA'sı için Apple imzalama kimliklerini ekleyip `Xcodebuild for Devices` ile Archive & Export yapın.
- IPA'yı Testing Distribution'a yükleyebilirsiniz. iOS cihaz kurulumu için uygun şekilde imzalanmış ve provisioning profile ile yetkilendirilmiş IPA gerekir.

## Codemagic önizleme

- iOS Simulator için `iphonesimulator` hedefli `.app` artifact üretin.
- Build tamamlandığında uygun `.app` artifact yanında Quick Launch görünürse tarayıcıdaki App Preview ile açın.
- Codemagic'in güncel dokümanına göre App Preview Teams planı gerektirir; Pay as you go ekiplerinde 100 dakikalık deneme sonrası dakika başına ücret uygulanabilir.
- Quick Launch yoksa build artifact hedefi simülatör için üretilmemiştir.

## Yapılandırılması gerekenler / bilinen eksikler

1. `Info.plist` ve OneSignal extension sürüm/build numarası Xcode `MARKETING_VERSION` ve `CURRENT_PROJECT_VERSION` değerlerine bağlandı; Xcode proje ayarları 1.00.2 / 39.
2. Google Sign-In için gerçek iOS OAuth client ID'ye karşılık gelen reversed client ID URL scheme'i Google Cloud Console'dan alınmalı ve Xcode URL Types'e eklenmelidir. Bu bilgi kaynak ZIP'inde bulunmadığından tahmin edilmedi.
3. Apple Sign In için Apple Developer portalında App ID capability ve Team ID yapılandırması gerekir; entitlements dosyasında Default yetkisi tanımlı.
4. Apple In-App Purchase/StoreKit ürün sorgulama, satın alma, geri yükleme ve sunucu doğrulama akışı bu kaynakta henüz yok. Native ödeme metotları bilerek `NOT_CONFIGURED` döndürüyor.
5. OneSignal APNs key, App Group ve Push capability Apple hesabında yapılandırılmalı.
6. Associated Domains için `rizedijital.com` ve `www.rizedijital.com` AASA dosyaları sunucuda doğrulanmalı.
7. iOS tarafındaki web giriş/ödeme UI davranışı canlı web projesinde bulunduğundan, bu ZIP tek başına web JavaScript entegrasyonunun doğru çalıştığını kanıtlamaz.

## Önemli

Bu paket iOS kaynaklarını ayırır ve görünen sürüm tutarsızlığını giderir. Xcode bu ortamda çalıştırılamadığı için yeni IPA/Simulator build sonucu iddia edilmez. Gerçek Apple Sign In, Google Sign-In callback, OneSignal, StoreKit ve canlı backend akışları ayrıca cihaz/simülatör üzerinde test edilmelidir.
