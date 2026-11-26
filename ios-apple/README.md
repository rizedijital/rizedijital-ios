# RizeDijital iOS - kaynak proje 1.00.19 (56)

Bu paket yalnızca iOS kaynaklarını içerir. Android ve web sunucusu dosyaları yoktur.

Codemagic deposunun kökünde `codemagic.yaml`, `release.json` ve `ios-apple/` yan yana bulunmalı.

## Kaynak kontrolü

```bash
cd ios-apple
npm ci
npm run verify:versions
npm run verify:ios
npm run verify:release
```

`npm run sync:ios` veya `npx cap sync ios` komutu için macOS/Xcode build ortamını kullanın. Kod imzalama ve gerçek özellik testleri bu statik doğrulamaların kapsamında değildir.

## Codemagic

- `rizedijital-ios-simulator`: imzasız simülatör .app ve ekran görüntüsü.
- `rizedijital-ios-signed`: sertifika/provisioning ve App Store Connect entegrasyonu ile imzalı IPA ve TestFlight.
- Her iki hedef (App ve OneSignalNotificationServiceExtension) için signing ayarlarını doğrulayın.
- Google iOS OAuth client ID, canlı `/api/mobil-yapilandirma?platform=ios` public yanıtından alınır.
- StoreKit sandbox, OAuth, Apple girişi, APNs ve konum testlerini TestFlight'ta ayrı yapın.

Ayrıntılar: kökte `IOS-PAKET-DUZELTME-RAPORU.md`.
