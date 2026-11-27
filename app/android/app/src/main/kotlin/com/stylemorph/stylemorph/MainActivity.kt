package com.stylemorph.stylemorph

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val SCREENSHOT_CHANNEL =
            "com.stylemorph.stylemorph/screenshot_protection"
        private const val APP_UPDATER_CHANNEL =
            "com.stylemorph.stylemorph/app_updater"
        private const val SCREEN_LOCK_CHANNEL =
            "com.stylemorph.stylemorph/screen_lock"
    }

    private var screenLockChannel: MethodChannel? = null
    private var screenOffReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure FLAG_SECURE is cleared on startup; Dart's ScreenshotProtectionService
        // controls enabling it via MethodChannel when kEnableScreenshotProtection is true.
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREENSHOT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecureFlag") {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUpdatesCacheDir" -> {
                        try {
                            val dir = File(cacheDir, "updates")
                            if (!dir.exists()) {
                                dir.mkdirs()
                            }
                            result.success(dir.absolutePath)
                        } catch (e: Exception) {
                            result.error("CACHE_DIR_ERROR", e.message, null)
                        }
                    }
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "filePath is required", null)
                            return@setMethodCallHandler
                        }
                        val apkFile = File(filePath)
                        if (!apkFile.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                apkFile
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_ACTIVITY_NEW_TASK
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        screenLockChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_LOCK_CHANNEL
        )
        unregisterScreenOffReceiver()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    screenLockChannel?.invokeMethod("onScreenLocked", null)
                }
            }
        }
        registerReceiver(receiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
        screenOffReceiver = receiver
    }

    private fun unregisterScreenOffReceiver() {
        val receiver = screenOffReceiver ?: return
        try {
            unregisterReceiver(receiver)
        } catch (_: Exception) {
        } finally {
            screenOffReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterScreenOffReceiver()
        screenLockChannel = null
        super.onDestroy()
    }
}
