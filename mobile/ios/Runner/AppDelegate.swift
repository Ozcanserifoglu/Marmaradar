import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let mapsApiKeyChannel = "com.radaralert.radar_alert/maps_api_key"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK. Set MAPS_API_KEY in ios/Flutter/MapsSecrets.xcconfig.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerMapsApiKeyChannel()
    return ok
  }

  private func registerMapsApiKeyChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: mapsApiKeyChannel,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getMapsApiKey" {
        let key =
          Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
        result(key)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
