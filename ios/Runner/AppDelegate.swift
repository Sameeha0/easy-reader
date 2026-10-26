import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // passes opened files to Flutter (same channel as Android's MainActivity)
    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "OpenFile")?.messenger() {
      let channel = FlutterMethodChannel(name: "easy_reader/open", binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "initialFile" {
          result(AppDelegate.pendingFile)
          AppDelegate.pendingFile = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      AppDelegate.channel = channel
    }
  }

  static var channel: FlutterMethodChannel?
  static var pendingFile: [String]?

  // copies the file so it can still be read after the other app lets go of it
  static func received(_ url: URL) {
    let copy = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
    let access = url.startAccessingSecurityScopedResource()
    try? FileManager.default.removeItem(at: copy)
    try? FileManager.default.copyItem(at: url, to: copy)
    if access { url.stopAccessingSecurityScopedResource() }
    let file = [copy.path, url.lastPathComponent]
    pendingFile = file
    channel?.invokeMethod("newFile", arguments: file)
  }
}
