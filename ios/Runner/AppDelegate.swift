import UIKit
import Flutter
import flutter_phone_lib
import Intents

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let logger = Logger()
    private let flutterSharedPreferences = FlutterSharedPreferences()
    private var segment: Segment?

    private var ringtonePath: String {
        let filename = "ringtone-\(Bundle.brandName)"

        if Bundle.main.path(forResource: filename, ofType: "wav") != nil {
            return "\(filename).wav"
        }
        
        return "ringtone.wav"
    }
    
    override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        addOnMissedCallNotificationPressedDelegate()

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        
        let registerPlugins = GeneratedPluginRegistrant.register
        registerPlugins(self)

        if (segment == nil) {
            segment = Segment(logger: self.logger, prefs: self.flutterSharedPreferences)
            segment?.initialize()
        }

        let middleware = Middleware(logger: self.logger, segment: self.segment!)

        startPhoneLib(
            registerPlugins,
            nativeMiddleware: middleware,
            onCallEnded: { (call) in
                self.segment?.track(event: "voip-call-ended", properties: [
                    "call_id" : middleware.currentCallInfo?.callId ?? "",
                    "correlation_id" : middleware.currentCallInfo?.correlationId ?? "",
                    "push_received_time" : middleware.currentCallInfo?.pushReceivedTime ?? "",
                    "reason" : call.reason,
                    "direction" : call.direction,
                    "duration" : call.duration,
                    "mos" : call.mos,
                    "middleware_url" : middleware.baseUrl,
                ])

                middleware.currentCallInfo = nil
            },
            onLogReceived: { message, level in
                self.logger.writeLog(message)
            },
            ringtonePath: self.ringtonePath
        )

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        ContactSortHostApiSetup(controller.binaryMessenger, ContactSortApi())
        NativeLoggingSetup(controller.binaryMessenger, logger)
        NativeMetricsSetup(controller.binaryMessenger, Metrics())
        CallScreenBehaviorSetup(controller.binaryMessenger, CallScreenBehaviorApi())
        TonesSetup(controller.binaryMessenger, SystemTones())
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    /// Handles receiving call starts from outside the application (e.g. contacts)
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let handle = userActivity.startCallHandle {
            segment?.track(event: "call-initiated-from-os", properties: [:])
            let number = handle.replacingOccurrences(of: "[^0-9\\+]", with: "", options: .regularExpression)
            startCall(number: number)
        }
        
        return true
    }
    
    override func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data) {
        flutterSharedPreferences.remoteNotificationToken = String(deviceToken: deviceToken)
    }

    override func application(_ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError
                    error: Error) {
        logger.writeLog("Failed to register for remote notifications: \(error).")
    }
}

protocol SupportedStartCallIntent {
    var contacts: [INPerson]? { get }
}

extension INStartAudioCallIntent: SupportedStartCallIntent {}

extension NSUserActivity {
    var startCallHandle: String? {
        guard let startCallIntent = interaction?.intent as? SupportedStartCallIntent else {
            return nil
        }
        return startCallIntent.contacts?.first?.personHandle?.value
    }
}

extension Bundle {
    internal static var brandName: String {
        return (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "").lowercased()
    }
}

extension String {
    fileprivate init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}
