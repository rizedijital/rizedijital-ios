# RizeDijital – Apple yinelenen derleme hatası için güvenli yayınlama

Bu paket 1.00.19 sürümüne ait önceki düzeltilmiş tam iOS kaynağına dayanır. Mevcut uygulama kodu ve OneSignal uzantısı korunmuştur.

## Neden önceki paket hata verebildi?

Önceki `codemagic.yaml`, `APP_STORE_APPLE_ID` yoksa yalnızca Codemagic sayacından Build Number türetiyor ve Apple'a ait yükleme geçmişini kontrol etmiyordu. Ayrıca oluşturulan IPA'nın *gerçek* `CFBundleVersion` değeri doğrulanmıyordu. Aynı değer daha önce Apple'a yüklendiyse Apple `The provided entity includes an attribute with a value that has already been used` hatası verebilir.

## Zorunlu Codemagic ayarı

1. App Store Connect > Uygulamalarım > RizeDijital > Uygulama Bilgileri bölümündeki **sayısal Apple ID** değerini öğrenin. Bu, `com.rizedijital.app` Bundle ID değildir.
2. Codemagic > Uygulama > Environment variables bölümünde `APP_STORE_APPLE_ID` adlı değişkeni bu sayıya ayarlayın. İlgili iş akışına erişebilir olmalı.
3. ZIP içindeki **güncel** `codemagic.yaml` dosyasının Git deposunun en üst dizininde bulunduğundan emin olun. Projenin `ios-apple/` dizini aynı seviyede olmalı.
4. `rizedijital-ios-signed` iş akışını yeniden çalıştırın. Apple API erişimi yoksa işlem IPA yayınlamaya kalkışmadan durur.
5. Codemagic logunda `Apple highest: ... New: ...` ve `IPA main app: version=..., build=...` satırlarını kontrol edin.

Codemagic, `app-store-connect get-latest-build-number APPLE_ID --all-versions` ile Apple'ın tüm sürümlerdeki en yüksek derleme numarasını sorgular; yeni sayı bunun üzerinde seçilir. IPA içindeki App ve OneSignal extension sürümü/bundle kimliği ayrıca doğrulanır. Böylece sessizce eskisi yeniden yüklenmez.

## Kontrol sınırları

Apple API hesabına erişim ve gerçek macOS/Xcode IPA yükleme denemesi bu çalışma ortamında yapılamaz. Apple'da eşzamanlı yapılan başka yüklemeler, Apple tarafındaki işleme gecikmeleri veya farklı bir yayınlama iş akışı hâlâ ayrı kontrol gerektirir. Eğer yine hata görülürse Codemagic logundaki `Apple highest` ve `IPA main app` satırlarını, Apple detayındaki `previousBundleVersion` değerini paylaşın.
