# RizeDijital iOS — Codemagic kaynak paketi

Sürüm: **1.00.2 / build 39**  
Bundle ID: `com.rizedijital.app`  
Minimum iOS: `15.0`

Bu paket yalnız iOS derlemesi için gereken kaynakları içerir. Android projesi, Android Gradle dosyaları, node_modules, Pods ve yerel derleme önbellekleri çıkarılmıştır. Android uygulamasının kaynakları değiştirilmemiştir.

## Codemagic ile imzasız simülatör derlemesi

1. ZIP'i açın ve içindeki `RizeDijital-iOS-Codemagic` klasöründeki dosyaları GitHub deposunun kök dizinine yükleyin.
2. Codemagic'te **Add application** ile aynı GitHub deposunu bağlayın.
3. Workflow olarak `rizedijital-ios-simulator` seçin (veya `codemagic.yaml` dosyasını otomatik algılatın).
4. **Start new build** seçeneğine basın.
5. Build tamamlandığında `RizeDijital-iOS-Simulator-App.zip` artifact'ini indirin. Bu yalnız iOS Simulator içindir; normal iPhone'a yüklenemez ve App Store'a gönderilemez.

Bu workflow Mac mini M2 üzerinde `npm ci` → `npx cap sync ios` → Xcode Simulator build adımlarını çalıştırır. Apple Developer hesabı veya sertifika gerekmez.

## OneSignal bildirimleri

- OneSignal Capacitor eklentisi ve `OneSignalNotificationServiceExtension` hedefi korunmuştur.
- Ana uygulama ve bildirim uzantısı aynı App Group'u kullanır: `group.com.rizedijital.app.onesignal`.
- CocoaPods OneSignal SDK sürümü eklentinin podspec'inde sabitlenmiş `5.5.5` sürümüyle eşleştirilmiştir.
- Gerçek iPhone push bildirimi için Apple Developer hesabında Push Notifications + App Groups yetenekleri, APNs anahtarı ve OneSignal iOS platform ayarları gerekir. İmzasız simülatör derlemesi push teslimatını doğrulamaz.
- OneSignal App ID uygulamaya gömülü REST API anahtarıyla değil, web projesindeki mevcut mobil yapılandırma akışıyla alınmalıdır.

## Giriş ve ödemeler

Apple Sign In / Google Sign-In için OAuth ve Apple Developer tarafındaki gerçek uygulama kimlikleri ayrıca yapılandırılmalıdır. Apple IAP bu kaynakta aktif satın alma sağlayıcısı değildir; mevcut güvenli devre dışı bırakılmış durum korunur. Android Google Play Billing kodu bu pakette yoktur ve değiştirilmemiştir.

## Önemli sınır

Bu kaynaklar arşiv ve yapılandırma düzeyinde kontrol edilmiştir. Bu ortamda Xcode/macOS olmadığı için gerçek Xcode derlemesi, iPhone üzerinde oturum açma, APNs teslimatı veya App Store imzalı arşiv testi yapılamamıştır. İlk Codemagic build logunda hata oluşursa logu paylaşın.
