package com.radaralert.radar_alert

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mapsApiKeyChannel = "com.radaralert.radar_alert/maps_api_key"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mapsApiKeyChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "getMapsApiKey") {
                result.success(readMapsApiKey())
            } else {
                result.notImplemented()
            }
        }
    }

    /// Same key injected into the manifest from android/local.properties.
    private fun readMapsApiKey(): String {
        return try {
            val ai = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA,
            )
            ai.metaData?.getString("com.google.android.geo.API_KEY").orEmpty()
        } catch (_: Exception) {
            ""
        }
    }
}
