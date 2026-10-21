package com.the_lazy_bear_Club.my_pet_cat

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var launchLinks: LaunchLinkBridge? = null
    private var coldStartLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Only a fresh launch carries a link; a restored activity must not
        // re-run the widget route.
        coldStartLink = if (savedInstanceState == null) linkFrom(intent) else null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        launchLinks = LaunchLinkBridge(messenger, coldStartLink)
        PetWidgetBridge(applicationContext, messenger)
    }

    // singleTop: a widget tap while the app is running arrives here instead of
    // creating a second activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        launchLinks?.onNewLink(linkFrom(intent))
    }

    private fun linkFrom(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        // Reopening from Recents replays the old intent; ignore it.
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) return null
        return intent.dataString
    }
}
