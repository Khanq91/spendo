package com.kg.spendo.spendo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.app.PendingIntent
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONArray

class SpendoWidgetMedium : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        private val CAT_IDS = listOf(
            R.id.btn_cat_0, R.id.btn_cat_1,
            R.id.btn_cat_2, R.id.btn_cat_3
        )
        private val CAT_ICON_IDS = listOf(
            R.id.tv_cat_0_icon, R.id.tv_cat_1_icon,
            R.id.tv_cat_2_icon, R.id.tv_cat_3_icon
        )
        private val CAT_NAME_IDS = listOf(
            R.id.tv_cat_0_name, R.id.tv_cat_1_name,
            R.id.tv_cat_2_name, R.id.tv_cat_3_name
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout_medium)

            // Đọc categories từ SharedPreferences (được Flutter ghi vào)
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val catsJson = prefs.getString("flutter.widget_categories", null)

            data class CatData(val id: String, val name: String, val emoji: String)

            val cats = mutableListOf<CatData>()
            if (catsJson != null) {
                try {
                    val arr = JSONArray(catsJson)
                    for (i in 0 until minOf(arr.length(), 4)) {
                        val obj = arr.getJSONObject(i)
                        cats.add(CatData(
                            obj.getString("id"),
                            obj.getString("name"),
                            obj.getString("emoji")
                        ))
                    }
                } catch (_: Exception) {}
            }

            // Fallback nếu chưa có data
            val defaults = listOf(
                CatData("", "Ăn uống", "🍜"),
                CatData("", "Di chuyển", "🚗"),
                CatData("", "Mua sắm", "🛍️"),
                CatData("", "Học tập", "📚"),
            )
            val displayCats = if (cats.size >= 4) cats else defaults

            // Gán UI + intent cho từng category
            for (i in 0..3) {
                val cat = displayCats[i]
                views.setTextViewText(CAT_ICON_IDS[i], cat.emoji)
                views.setTextViewText(CAT_NAME_IDS[i], cat.name)

                val uri = if (cat.id.isNotEmpty())
                    Uri.parse("spendo://add?category_id=${cat.id}")
                else
                    Uri.parse("spendo://add")

                val intent = Intent(Intent.ACTION_VIEW, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                val pending = PendingIntent.getActivity(
                    context, i + 10, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(CAT_IDS[i], pending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}