import UIKit
import Capacitor
import AuthenticationServices
import GoogleSignIn
import Network
import StoreKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var socialAuthPluginRegistered = false
    private var nativePaymentsPluginRegistered = false
    private var nativeSettingsPluginsRegistered = false
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.rizedijital.app.network")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startNetworkRecovery()
        DispatchQueue.main.async { [weak self] in self?.registerSocialAuthPluginIfNeeded() }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        registerSocialAuthPluginIfNeeded()
    }

    private func registerSocialAuthPluginIfNeeded() {
        guard let bridgeVC = window?.rootViewController as? CAPBridgeViewController,
              let bridge = bridgeVC.bridge else { return }
        if !socialAuthPluginRegistered {
            bridge.registerPluginInstance(RizeDijitalSocialAuthPlugin())
            socialAuthPluginRegistered = true
        }
        if !nativePaymentsPluginRegistered {
            bridge.registerPluginInstance(RizeDijitalNativePaymentsPlugin())
            nativePaymentsPluginRegistered = true
        }
        if !nativeSettingsPluginsRegistered {
            bridge.registerPluginInstance(RizeDijitalLocationPermissionPlugin())
            bridge.registerPluginInstance(RizeDijitalPushPermissionPlugin())
            nativeSettingsPluginsRegistered = true
        }
    }

    private func startNetworkRecovery() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            DispatchQueue.main.async {
                guard let self,
                      let bridgeVC = self.window?.rootViewController as? CAPBridgeViewController,
                      let webView = bridgeVC.webView,
                      let current = webView.url?.absoluteString else { return }
                if current.contains("localhost") || current.contains("offline.html") || current.contains("_capacitor_server_error_") || current.hasPrefix("capacitor://") {
                    if let url = URL(string: "https://rizedijital.com") { webView.load(URLRequest(url: url)) }
                }
            }
        }
        pathMonitor.start(queue: pathQueue)
    }

    func applicationWillTerminate(_ application: UIApplication) { pathMonitor.cancel() }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) { return true }
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
}

@objc(RizeDijitalNativePaymentsPlugin)
public class RizeDijitalNativePaymentsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "RizeDijitalNativePaymentsPlugin"
    public let jsName = "RizeDijitalNativePayments"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getProducts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPurchases", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restorePurchases", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "finishTransaction", returnType: CAPPluginReturnPromise)
    ]

    @objc func getStatus(_ call: CAPPluginCall) {
        call.resolve(["platform": "ios", "provider": "apple_app_store", "configured": true, "storeKitVersion": 2])
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        let identifiers = call.getArray("productIds", String.self) ?? []
        if identifiers.isEmpty || identifiers.count > 12 {
            call.reject("App Store ürün kimlikleri eksik veya çok fazla.", "INVALID_PRODUCTS")
            return
        }
        Task { @MainActor in
            do {
                let products = try await Product.products(for: identifiers)
                let mapped: [[String: Any]] = products.map { item in
                    ["productId": item.id,
                     "displayName": item.displayName,
                     "formattedPrice": item.displayPrice,
                     "type": item.type == .autoRenewable ? "auto_renewable" : "other"]
                }
                call.resolve(["products": mapped])
            } catch {
                call.reject("App Store abonelik fiyatları alınamadı: \(error.localizedDescription)", "PRODUCTS_UNAVAILABLE")
            }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId"), !productId.isEmpty else {
            call.reject("Apple abonelik ürün kimliği eksik.", "NO_PRODUCT")
            return
        }
        let account = call.getString("appAccountToken") ?? ""
        Task { @MainActor in
            do {
                guard let product = try await Product.products(for: [productId]).first,
                      product.type == .autoRenewable else {
                    call.reject("Bu Apple aboneliği App Store'da bulunamadı.", "PRODUCT_NOT_FOUND")
                    return
                }
                var options: Set<Product.PurchaseOption> = []
                if let token = UUID(uuidString: account) { options.insert(.appAccountToken(token)) }
                let result = try await product.purchase(options: options)
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let tx):
                        // Sunucu Apple API doğrulaması tamamlanana kadar finish çağrılmaz.
                        call.resolve(Self.payload(for: tx))
                    case .unverified(_, _):
                        call.reject("App Store işlemi cihazda doğrulanamadı.", "UNVERIFIED")
                    }
                case .pending:
                    call.reject("Apple satın alımı onay bekliyor. Hesabınızı kontrol edin.", "PENDING")
                case .userCancelled:
                    call.reject("Satın alma iptal edildi.", "CANCELLED")
                @unknown default:
                    call.reject("Apple satın alma durumu tanınamadı.", "UNKNOWN_STATE")
                }
            } catch {
                call.reject("Apple satın alma başlatılamadı: \(error.localizedDescription)", "PURCHASE_FAILED")
            }
        }
    }

    @objc func getPurchases(_ call: CAPPluginCall) {
        Task { @MainActor in
            let products = await Self.activeTransactions()
            call.resolve(["purchases": products])
        }
    }

    @objc func restorePurchases(_ call: CAPPluginCall) {
        Task { @MainActor in
            do {
                // AppStore.sync() yalnız kullanıcının açık geri yükleme isteğinde çağrılır.
                try await AppStore.sync()
                let purchases = await Self.activeTransactions()
                call.resolve(["purchases": purchases])
            } catch {
                call.reject("Apple abonelikleri geri yüklenemedi: \(error.localizedDescription)", "RESTORE_FAILED")
            }
        }
    }

    @objc func finishTransaction(_ call: CAPPluginCall) {
        let requested = call.getString("transactionId") ?? ""
        if requested.isEmpty { call.reject("İşlem kimliği eksik.", "NO_TRANSACTION"); return }
        Task { @MainActor in
            for await item in Transaction.unfinished {
                if case .verified(let tx) = item, String(tx.id) == requested {
                    await tx.finish()
                    call.resolve(["finished": true])
                    return
                }
            }
            // İşlem daha önce tamamlanmışsa idempotent kabul et.
            call.resolve(["finished": true])
        }
    }

    private static func payload(for tx: Transaction) -> [String: Any] {
        return [
            "transactionId": String(tx.id),
            "originalTransactionId": String(tx.originalID),
            "productId": tx.productID,
            "expiresAt": tx.expirationDate?.timeIntervalSince1970 ?? 0
        ]
    }

    @MainActor private static func activeTransactions() async -> [[String: Any]] {
        var results: [[String: Any]] = []
        var seen = Set<String>()
        for await verification in Transaction.currentEntitlements {
            if case .verified(let tx) = verification {
                let id = String(tx.id)
                if !seen.contains(id) && tx.revocationDate == nil {
                    results.append(payload(for: tx))
                    seen.insert(id)
                }
            }
        }
        for await verification in Transaction.unfinished {
            if case .verified(let tx) = verification {
                let id = String(tx.id)
                if !seen.contains(id) && tx.revocationDate == nil {
                    results.append(payload(for: tx))
                    seen.insert(id)
                }
            }
        }
        return results
    }
}

@objc(RizeDijitalLocationPermissionPlugin)
public class RizeDijitalLocationPermissionPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "RizeDijitalLocationPermissionPlugin"
    public let jsName = "RizeDijitalLocationPermission"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openAppSettings", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openLocationSettings", returnType: CAPPluginReturnPromise)
    ]

    @objc func getStatus(_ call: CAPPluginCall) {
        let state = CLLocationManager.authorizationStatus()
        let granted = state == .authorizedAlways || state == .authorizedWhenInUse
        call.resolve(["permissionGranted": granted,
                      "fineGranted": granted,
                      "coarseGranted": granted,
                      "servicesEnabled": CLLocationManager.locationServicesEnabled()])
    }

    @objc func openAppSettings(_ call: CAPPluginCall) {
        openSettings(call)
    }

    @objc func openLocationSettings(_ call: CAPPluginCall) {
        // iOS sistem Konum Servisleri paneli için özel deep link sunmaz; uygulama ayarlarını aç.
        openSettings(call)
    }

    private func openSettings(_ call: CAPPluginCall) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            call.reject("iOS uygulama ayarları açılamadı.")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { opened in
                call.resolve(["opened": opened, "target": "application_details_settings"])
            }
        }
    }
}

@objc(RizeDijitalPushPermissionPlugin)
public class RizeDijitalPushPermissionPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "RizeDijitalPushPermissionPlugin"
    public let jsName = "RizeDijitalPushPermission"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openSettings", returnType: CAPPluginReturnPromise)
    ]

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    @objc func getStatus(_ call: CAPPluginCall) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            call.resolve(["granted": authorized, "runtimePermissionGranted": authorized,
                          "notificationsEnabled": authorized,
                          "settingsRequired": settings.authorizationStatus == .denied,
                          "canRequestPermission": settings.authorizationStatus == .notDetermined,
                          "simulator": self.isSimulator, "settingsOpened": false,
                          "settingsTarget": "", "sdkInt": 0])
        }
    }

    // Sistemin izin penceresi kullanici dokunusuyla acilir; APNs aboneligi
    // bu izinle karistirilmaz (simulator remote push teslimi dogrulanamaz).
    @objc func requestPermission(_ call: CAPPluginCall) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                call.reject("iOS bildirim izni istenemedi: \(error.localizedDescription)")
                return
            }
            call.resolve(["granted": granted, "simulator": self.isSimulator])
        }
    }

    @objc func openSettings(_ call: CAPPluginCall) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            call.reject("iOS bildirim ayarları açılamadı.")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { opened in
                call.resolve(["opened": opened, "settingsOpened": opened, "settingsTarget": "application_details_settings"])
            }
        }
    }
}

@objc(RizeDijitalSocialAuthPlugin)
public class RizeDijitalSocialAuthPlugin: CAPPlugin, CAPBridgedPlugin, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    public let identifier = "RizeDijitalSocialAuthPlugin"
    public let jsName = "RizeDijitalSocialAuth"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signInGoogle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "signInApple", returnType: CAPPluginReturnPromise)
    ]

    private var appleCall: CAPPluginCall?
    private var appleController: ASAuthorizationController?

    @objc func signInGoogle(_ call: CAPPluginCall) {
        guard let presenter = bridge?.viewController else {
            call.reject("Google giriş ekranı hazırlanamadı.")
            return
        }
        guard let iosClientId = call.getString("iosClientId"), !iosClientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            call.reject("Google iOS OAuth Client ID yapılandırılmamış.")
            return
        }
        guard let serverClientId = call.getString("serverClientId"), !serverClientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            call.reject("Google server client ID yapılandırılmamış.")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: iosClientId, serverClientID: serverClientId)
        DispatchQueue.main.async {
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    call.reject(error.localizedDescription, nil, error)
                    return
                }
                guard let user = result?.user, let idToken = user.idToken?.tokenString, !idToken.isEmpty else {
                    call.reject("Google ID token alınamadı.")
                    return
                }
                call.resolve([
                    "idToken": idToken,
                    "email": user.profile?.email ?? "",
                    "name": user.profile?.name ?? "",
                    "givenName": user.profile?.givenName ?? "",
                    "familyName": user.profile?.familyName ?? "",
                    "picture": user.profile?.imageURL(withDimension: 320)?.absoluteString ?? ""
                ])
            }
        }
    }

    @objc func signInApple(_ call: CAPPluginCall) {
        guard appleCall == nil else {
            call.reject("Apple giriş işlemi zaten devam ediyor.")
            return
        }
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        if let state = call.getString("state"), !state.isEmpty { request.state = state }
        if let nonce = call.getString("nonce"), !nonce.isEmpty { request.nonce = nonce }

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        appleCall = call
        appleController = controller
        DispatchQueue.main.async { controller.performRequests() }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let call = appleCall else { return }
        defer {
            appleCall = nil
            appleController = nil
        }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            call.reject("Apple kimlik bilgisi alınamadı.")
            return
        }
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              !identityToken.isEmpty else {
            call.reject("Apple identity token alınamadı.")
            return
        }
        let formatter = PersonNameComponentsFormatter()
        let name = credential.fullName.map { formatter.string(from: $0) } ?? ""
        let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        call.resolve([
            "identityToken": identityToken,
            "authorizationCode": authorizationCode,
            "email": credential.email ?? "",
            "name": name,
            "state": credential.state ?? ""
        ])
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let call = appleCall else { return }
        appleCall = nil
        appleController = nil
        call.reject(error.localizedDescription, nil, error)
    }

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let anchor = bridge?.viewController?.view.window { return anchor }
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                return window
            }
        }
        return UIWindow(frame: UIScreen.main.bounds)
    }
}
