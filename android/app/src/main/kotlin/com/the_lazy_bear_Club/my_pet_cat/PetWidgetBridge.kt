package com.the_lazy_bear_Club.my_pet_cat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Build
import com.the_lazy_bear_Club.my_pet_cat.widget.PetWidgetProvider
import com.the_lazy_bear_Club.my_pet_cat.widget.PetWidgetStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Receives widget payloads from Dart and offers the launcher's pin prompt. */
class PetWidgetBridge(private val context: Context, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, "my_pet_cat/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    (call.arguments as? Map<*, *>)?.let {
                        PetWidgetStore.write(context, it)
                        PetWidgetProvider.updateAll(context)
                    }
                    result.success(null)
                }
                "canRequestPin" -> result.success(canPin())
                "requestPin" -> {
                    val size = call.arguments as? String ?: "medium"
                    result.success(
                        canPin() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            AppWidgetManager.getInstance(context).requestPinAppWidget(
                                PetWidgetProvider.componentFor(context, size), null, null,
                            ),
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canPin(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported
}
