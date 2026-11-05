import UIKit
import Capacitor
import AuthenticationServices
import GoogleSignIn
import Network

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var socialAuthPluginRegistered = false
    private var nativePaymentsPluginRegistered = false
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
                    if let url = URL(string: "https://www.rizedijital.com") { webView.load(URLRequest(url: url)) }
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
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise)
    ]

    @objc func getStatus(_ call: CAPPluginCall) {
        call.resolve([
            "platform": "ios",
            "provider": "apple_app_store",
            "configured": false
        ])
    }

    @objc func purchase(_ call: CAPPluginCall) {
        call.reject("Apple ödeme yöntemi şu anda aktif değil.", "NOT_CONFIGURED")
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
