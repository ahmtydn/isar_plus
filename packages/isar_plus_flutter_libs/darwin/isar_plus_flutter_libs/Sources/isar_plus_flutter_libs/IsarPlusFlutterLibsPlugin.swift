import Foundation

#if canImport(FlutterMacOS)
import FlutterMacOS
#elseif canImport(Flutter)
import Flutter
#endif

@_silgen_name("isar_version")
func isar_version() -> UInt32

public class IsarPlusFlutterLibsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Dummy call to prevent the linker from stripping the Isar library
        let _ = isar_version()
    }
}
