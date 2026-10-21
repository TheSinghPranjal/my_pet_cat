package com.the_lazy_bear_Club.my_pet_cat

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Hands launch links to Dart over `my_pet_cat/launch`.
 *
 * The cold-start link is handed over once, when Dart asks for it, and then
 * cleared. Later links are pushed with `onLink`; any that arrive before Dart
 * has asked are kept as the initial link, so none are lost or doubled.
 */
class LaunchLinkBridge(messenger: BinaryMessenger, private var initialLink: String?) {
    private val channel = MethodChannel(messenger, "my_pet_cat/launch")
    private var dartReady = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialLink" -> {
                    dartReady = true
                    result.success(initialLink)
                    initialLink = null
                }
                else -> result.notImplemented()
            }
        }
    }

    fun onNewLink(link: String?) {
        if (link == null) return
        if (dartReady) channel.invokeMethod("onLink", link) else initialLink = link
    }
}
