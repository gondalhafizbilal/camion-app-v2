package com.camiontrading.app

import android.app.Application
import android.content.pm.ApplicationInfo
import android.util.Log
import com.tiktok.TikTokBusinessSdk
import com.tiktok.TikTokBusinessSdk.TTConfig

class CamionApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val isDebugBuild =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        val appSecret = getString(R.string.tiktok_app_secret).trim()
        val ttAppId = getString(R.string.tiktok_tt_app_id).trim()

        if (appSecret.isBlank() || ttAppId.isBlank()) {
            if (isDebugBuild) {
                Log.w(TAG, "TikTok SDK not initialized: missing app secret or TT app id")
            }
            return
        }

        val ttConfig = TTConfig(applicationContext, appSecret)
            .setAppId(packageName)
            .setTTAppId(ttAppId)

        TikTokBusinessSdk.initializeSdk(ttConfig, object : TikTokBusinessSdk.TTInitCallback {
            override fun success() {
                if (isDebugBuild) {
                    Log.i(TAG, "TikTok SDK initialized successfully")
                }
            }

            override fun fail(code: Int, msg: String) {
                if (isDebugBuild) {
                    Log.e(TAG, "TikTok SDK initialization failed: $code $msg")
                }
            }
        })
    }

    companion object {
        private const val TAG = "CamionApplication"
    }
}
