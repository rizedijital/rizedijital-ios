# RizeDijital 1.00.18 (55) — yalnız iOS / Codemagic

## GitHub dosya dizilimi
ZIP'i açıp **içeriğini** `rizedijital-ios` deposunun köküne koyun; `codemagic.yaml` ile `mobile-app/` aynı dizinde bulunmalıdır. ZIP'i olduğu gibi GitHub'a yüklemeyin. Dosyaları bir Git istemcisiyle veya GitHub arayüzüyle mevcut dosyaların üzerine yerleştirin; eski `mobile-app/android` klasörünü eklemeyin.

## Codemagic'te ücretsiz/hesap açmadan simülatör
1. Depo `main` dalına commit edin.
2. Codemagic → RizeDijital iOS → Start new build → Branch `main` → Workflow `rizedijital-ios-simulator`.
3. `Install npm dependencies`, `Synchronize Capacitor iOS`, `Install CocoaPods`, `Build iOS Simulator`, `Test iOS Simulator startup` aşamalarını kontrol edin.
4. Başarılı build'de `App.app.zip` simülatör uygulamasını ve test adımındaki `ios-preview.png` ekran görüntüsünü Artifacts bölümünden alın.
5. Appetize / Codemagic Quick Launch canlı simülatör denemeleri; harici servislerde oturum hatası yaşanırsa `simctl INSTALL/LAUNCH` ve ekran görüntüsü testiyle hata ayırın.

## iOS giriş ve bildirimler
- Native Google login için Admin → Mobil Ayarlar → iOS Google açık, Google sunucu Client ID + iOS OAuth Client ID dolu, uygulamada `REVERSED_CLIENT_ID` URL scheme doğru tanımlanmış olmalıdır.
- iOS Apple girişini panelden açabilirsiniz; gerçek giriş Apple Developer hesabı + Sign in with Apple yetkisi + düzgün imzalama olmadan tamamlanmaz.
- `RizeDijitalPushPermissionPlugin.requestPermission` kullanıcı `Bildirimleri Aç` butonuna basınca iOS sistem izni ister. Simülatörde **izin ekranı** görülebilir, gerçek OneSignal/APNs push iletimini doğrulamak için Apple Developer, APNs yapılandırması ve gerçek cihaz testleri gerekir.
- iOS üstte boş alanın azaltılması için native iOS'a özgü header kuralı eklenmiştir; **sonuç gerçek simülatör ekran görüntüsünde kontrol edilmelidir**. Canlı ekranda henüz doğrulanmamıştır.

## İmzalı IPA (sonraki aşama)
Apple Developer hesabı etkinleşince Codemagic `rizedijital-ios-signed` workflow'unda `REPLACE_WITH_YOUR_CODEMAGIC_API_KEY_NAME` yerini kendi App Store Connect entegrasyon referansınızla değiştirin. Ana uygulama ve OneSignal extension için Apple Distribution/provisioning profile gereklidir. Mac gerekmez, ancak Apple ücretli geliştirici üyeliği gerekir. Şu paket gerçek imzalı IPA değildir.

## Kapsam/sürüm
Bu ZIP iOS native kaynakları, `mobile-app/www`, npm lock, Capacitor, Codemagic ve iOS önizleme test betiklerini içerir. Android native, web PHP sunucu ve SQL içermez. Uygulama version 1.00.18 / iOS build 55, OneSignal extension 1.00.18/55. Android'de yayınlanan 1.00.14 (code51) aynı kalır; Android'in ilerideki kaynak hedefinin 1.00.18 olması ayrı işlem gerektirir.
