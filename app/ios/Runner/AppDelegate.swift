import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screenLockChannel: FlutterMethodChannel?
  private var screenLockObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.stylemorph.stylemorph/screen_lock",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.screenLockChannel = channel
    if screenLockObserver == nil {
      screenLockObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.screenLockChannel?.invokeMethod("onScreenLocked", arguments: nil)
      }
    }
  }

  deinit {
    if let observer = screenLockObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}
