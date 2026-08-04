#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif
import CIsarCore

public class IsarPlusFlutterLibsPlugin: NSObject, FlutterPlugin {
    public private(set) static var coreVersion: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        if let version = isar_plus_version() {
            coreVersion = String(cString: version)
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
}
