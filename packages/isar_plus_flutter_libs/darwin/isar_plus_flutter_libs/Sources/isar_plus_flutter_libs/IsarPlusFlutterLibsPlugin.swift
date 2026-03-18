import Foundation

#if canImport(FlutterMacOS)
import FlutterMacOS
#elseif canImport(Flutter)
import Flutter
#endif

public class IsarPlusFlutterLibsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // This plugin only bundles the Isar native binary.
        // No method channel or platform interaction needed.
    }
}
