# RizeDijital iOS 1.00.19 / build 56 - Kurulum

ZIP içindeki `RizeDijital_iOS_1.00.19_Build56_Full` klasörünün **içeriğini** Git deposunun köküne taşıyın. `codemagic.yaml`, `release.json`, `ios-apple/` aynı seviyede olmalı.

1. Codemagic'te bu Git deposunu bağlayın.
2. Simülatör için `rizedijital-ios-simulator`, imzalı IPA için `rizedijital-ios-signed` iş akışını seçin.
3. İmzalı iş akışında App Store Connect entegrasyonu, dağıtım sertifikası ve App + OneSignal extension provisioning profillerini yapılandırın.
4. `ios-apple` klasöründe `npm ci && npm run verify:versions && npm run verify:ios && npm run verify:release` kontrollerini çalıştırın.
5. Yeni mağaza yayını için önce App Store Connect'teki sürümü kontrol edin; **1.00.18 (55) zaten yayımdadır; bu paket 1.00.19 (56) olarak hazırlanmıştır. App Store Connect’te 1.00.19 sürümünü açın.**

Android kaynakları bu ZIP'te yoktur. Swift/StoreKit/OneSignal özelliklerinin iş mantığı değiştirilmemiştir.
