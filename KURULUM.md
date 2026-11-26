# RizeDijital iOS - Codemagic ve Google OAuth

Bu iOS-only pakette `ios-apple/` uygulama köküdür. Kök dizindeki `codemagic.yaml` iş akışlarını yönetir.

Google ile iOS girişi için `ios-apple/scripts/configure-ios-google-client.mjs`, güvenli HTTPS `https://rizedijital.com/api/mobil-yapilandirma?platform=ios` yanıtındaki **public** iOS OAuth Client ID'yi okuyup `Info.plist` URL scheme alanına ekler. Canlı yanıt beklenen biçimde değilse açık hata verir; gizli anahtar ZIP'e eklenmez.

App Store imzalama için Codemagic entegrasyon adı ve Apple Developer'da her iki bundle kimliği gereklidir. Uygulama zaten yayımlanmış olduğu için güncellemede yeni mağaza sürümü/build numarası ayrıca ayarlanmalıdır.

Devamı `IOS-PAKET-DUZELTME-RAPORU.md` dosyasında.
