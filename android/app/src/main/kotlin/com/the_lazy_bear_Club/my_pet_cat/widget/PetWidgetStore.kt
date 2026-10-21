package com.the_lazy_bear_Club.my_pet_cat.widget

import android.content.Context
import com.the_lazy_bear_Club.my_pet_cat.R

/** The small payload the app shares with the widget (see PetWidgetPayload in Dart). */
object PetWidgetStore {
    private const val PREFS = "my_pet_cat_widget"
    private const val SCHEMA_VERSION = 1

    data class State(val pose: String, val lastInteraction: String?) {
        fun greeting(context: Context): String =
            lastInteraction ?: context.getString(R.string.widget_greeting)
    }

    fun read(context: Context): State {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // A newer app may have written a schema this widget code doesn't know.
        if (prefs.getInt("schemaVersion", SCHEMA_VERSION) > SCHEMA_VERSION) return State("idle", null)
        return State(
            pose = prefs.getString("pose", null) ?: "idle",
            lastInteraction = prefs.getString("lastInteraction", null),
        )
    }

    fun write(context: Context, payload: Map<*, *>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt("schemaVersion", (payload["schemaVersion"] as? Number)?.toInt() ?: SCHEMA_VERSION)
            .putString("pose", payload["pose"] as? String)
            .putString("location", payload["location"] as? String)
            .putString("lastInteraction", payload["lastInteraction"] as? String)
            .putLong("updatedAt", (payload["updatedAt"] as? Number)?.toLong() ?: 0L)
            .apply()
    }
}
