# RizeDijital — yalnizca iOS derleme kaynaklari — 1.00.18 (build 55)

Bu paket **Android klasoru, web sunucu PHP dosyalari, SQL migrasyonlari veya canli sunucu konfigurasyonu** icermez.
`mobile-app/www` klasoru, iOS Capacitor derlemesinin gerektirdigi yerel acilis/cevrimdisi varliklaridir; web sunucu projesi degildir.

## Windows + Codemagic (Apple hesabi gerekmeden simulator)
1. ZIP'i acin ve `codemagic.yaml`, `release.json` ile `mobile-app/` klasorunu birlikte Git deposunun kokune yerlestirin.
2. Codemagic'te bu depoyu ekleyin; `rizedijital-ios-simulator` is akisiyla derleyin.
3. Basarili derleme sonucu simulator `.app` dosyasi `Artifacts` bolumunde gorulur. Bu dosya imzali IPA degildir.
4. App Preview veya harici simulator hizmeti uygunluguna bagli olarak tarayicidan onizleme yapilabilir. Simulator derlemesi tek basina tarayicida canli onizleme garantilemez.

## Ileride Apple Developer hesabi ile imzali IPA
1. Apple Developer Program uyeligi edinip App ID, OneSignal uzantisi ve App Group ayarlarini yapin.
2. App Store Connect API anahtarini Codemagic'e baglayin ve code signing identity/provisioning profile ekleyin.
3. `codemagic.yaml` icindeki `REPLACE_WITH_YOUR_CODEMAGIC_API_KEY_NAME` yerini Codemagic entegrasyon referans adi ile degistirin.
4. `rizedijital-ios-signed` is akisiyla IPA uretin. Apple anahtarlari ZIP icinde bulunmaz.

## Kaynak dogrulama
Node.js 22+ ile `cd mobile-app`, `npm ci`, `npm run verify:versions`, `npm run verify:ios` ve `npx cap sync ios`.
`npm ci` icin indirilebilir npm bagimliliklari gerekir. Gercek Xcode/StoreKit/APNs testleri bu konteynerde gerceklestirilmemistir.
