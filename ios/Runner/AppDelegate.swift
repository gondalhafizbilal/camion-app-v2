import Flutter
import AppTrackingTransparency
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let tiktokChannelName = "tiktok_business_sdk"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
     UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    application.registerForRemoteNotifications()
    NSLog("[TIKTOK][NATIVE] didFinishLaunching - initializing SDK")
    TTInitializeTikTokBusinessSDK()
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    DispatchQueue.main.async { [weak self] in
      self?.setupTikTokChannel()
      NSLog("[TIKTOK][NATIVE] method channel setup attempted")
    }
    return result
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(application, open: url, options: options)
  }

  private func setupTikTokChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: tiktokChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "initialize":
        NSLog("[TIKTOK][NATIVE] initialize() received")
        TTInitializeTikTokBusinessSDK()
        NSLog("[TIKTOK][NATIVE] initialize() completed")
        result(nil)
      case "requestTrackingAuthorization":
        NSLog("[TIKTOK][NATIVE] requestTrackingAuthorization() received")
        if #available(iOS 14, *) {
          ATTrackingManager.requestTrackingAuthorization { status in
            NSLog("[TIKTOK][NATIVE] ATT status: \(status.rawValue)")
            result(status.rawValue)
          }
        } else {
          result(0)
        }
      case "identify", "trackBaseEvent", "trackContentsEvent":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Expected a map of arguments.", details: nil))
          return
        }
        if call.method == "identify" {
          NSLog("[TIKTOK][NATIVE] identify() received")
          TTTrackTikTokIdentify(
            arguments["externalId"] as? String,
            arguments["externalUserName"] as? String,
            arguments["phoneNumber"] as? String,
            arguments["email"] as? String
          )
          NSLog("[TIKTOK][NATIVE] identify() completed")
          result(nil)
        } else if call.method == "trackBaseEvent" {
          guard let eventName = arguments["eventName"] as? String else {
            result(FlutterError(code: "missing_event_name", message: "eventName is required.", details: nil))
            return
          }
          NSLog("[TIKTOK][NATIVE] trackBaseEvent() received: \(eventName)")
          TTTrackTikTokBaseEvent(eventName, arguments["eventId"] as? String)
          NSLog("[TIKTOK][NATIVE] trackBaseEvent() completed: \(eventName)")
          result(nil)
        } else if call.method == "trackContentsEvent" {
          guard let eventType = arguments["eventType"] as? String else {
            result(FlutterError(code: "missing_event_type", message: "eventType is required.", details: nil))
            return
          }
          NSLog("[TIKTOK][NATIVE] trackContentsEvent() received: \(eventType)")
          TTTrackTikTokContentsEvent(
            eventType,
            arguments["properties"] as? [String: Any],
            arguments["eventId"] as? String
          )
          NSLog("[TIKTOK][NATIVE] trackContentsEvent() completed: \(eventType)")
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
