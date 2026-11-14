# RizeDijital — 1.00.18 güncelleme durumu

- Web ve hedef iOS sürümü: **1.00.18**.
- iOS native build numarası: **55**, OneSignal Extension: **55**.
- Android yayınlanmış kapalı test: **1.00.14 / versionCode 51** (bu güncellemeyle değişmedi).
- Android sonraki kaynak hedefi metadata: **1.00.18 / versionCode 55**, ancak burada Android kaynakları/derlemesi **verilmiyor**.
- Önceki çalışan Codemagic simulator kurulumu, OneSignal extension `CFBundleExecutable`, Swift `pluginMethods` ve Xcode bundle resource düzeltmeleri korundu.
- Yeni: admin native Google Android, Google iOS, Apple iOS ayrı anahtarları; iOS native buton sunucu çıktısı; iOS UNUserNotificationCenter izin akışı; iOS mobile header stil düzeni.
- PHP dosyaları `php -l`, JavaScript `node --check`, Swift `swiftc -frontend -parse`, iOS sürüm/doğrulama, plist ve YAML ayrıştırma kontrolü ve 15 PHP davranış testi **yerel olarak geçmiştir**.
- **Henüz doğrulanmayanlar:** gerçek Codemagic 1.00.18 derlemesi, iOS görüntü/layout, gerçek Apple/Google sosyal login, iPhone APNs/OneSignal bildirim teslimi ve StoreKit canlı satın alma.
- Mağaza Abonelikleri 500 hata V2 düzeltmesi veya tasarım dosyaları bu iki güncelleme paketinde değiştirilmez.
