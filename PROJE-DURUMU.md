# RizeDijital iOS — kaynak paket durumu

- App Store’da yayımlanmış eski sürüm: **1.00.18 (55)**. Yeni derleme hedefi: **1.00.19 (56)**.
- Paket yalnız iOS kaynakları içerir: `ios-apple/`. Android/Web projeleri ve PHP sunucusu kapsam dışında.
- Ana uygulama ve OneSignal Notification Service Extension build ayarları **56** olarak uyumlu.
- Codemagic kök dosyası `codemagic.yaml`; imzasız simulator ve imzalı IPA iş akışları vardır.
- Google iOS OAuth URL scheme, canlı public API yanıtına göre Codemagic'te hazırlanır.
- Apple/Google native sosyal giriş, StoreKit, OneSignal/APNs, konum ve ses tanıma Swift kodları korunmuştur.
- Node kaynak kontrolleri başarılı: `verify:versions`, `verify:ios`, `verify:release`.
- macOS/Xcode/CocoaPods Podfile.lock çözümlemesi, gerçek imzalı IPA, fiziksel cihaz, Apple/Google giriş, APNs ve Sandbox satın alma bu ortamda doğrulanamamıştır.
- Yeni sürüm 1.00.19 (56) için App Store Connect’te 1.00.19 sürüm kaydı açılmalıdır; 56 başka bir yüklemede kullanılmışsa build numarası yeniden yükseltilmelidir.

Diğer ayrıntılar: `IOS-PAKET-DUZELTME-RAPORU.md`.
