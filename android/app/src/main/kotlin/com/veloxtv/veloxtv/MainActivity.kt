package com.veloxtv.veloxtv

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.media.tv.TvContract
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.veloxtv.app/tv_channel"
    private var channelMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channelMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channelMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "syncFavorites" -> {
                    val favorites = call.argument<List<Map<String, Any>>>("channels") ?: emptyList()
                    thread {
                        try {
                            syncFavoritesToTvHomeScreen(favorites)
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            runOnUiThread { result.success(false) }
                        }
                    }
                }
                "getInitialChannelId" -> {
                    val channelId = intent?.getStringExtra("launch_channel_id")
                    result.success(channelId)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val channelId = intent.getStringExtra("launch_channel_id")
        if (channelId != null) {
            channelMethodChannel?.invokeMethod("onChannelSelectedFromHome", channelId)
        }
    }

    private fun syncFavoritesToTvHomeScreen(favorites: List<Map<String, Any>>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        try {
            val resolver = contentResolver

            // 1. Check if "VeloxTV Favorites" channel already exists
            var targetChannelId: Long = -1L
            val projection = arrayOf(TvContract.Channels._ID, TvContract.Channels.COLUMN_DISPLAY_NAME)
            val cursor: Cursor? = resolver.query(
                TvContract.Channels.CONTENT_URI,
                projection,
                null,
                null,
                null
            )

            cursor?.use {
                val idIndex = it.getColumnIndex(TvContract.Channels._ID)
                val nameIndex = it.getColumnIndex(TvContract.Channels.COLUMN_DISPLAY_NAME)
                while (it.moveToNext()) {
                    val name = if (nameIndex >= 0) it.getString(nameIndex) else null
                    if (name == "VeloxTV Favorites") {
                        targetChannelId = if (idIndex >= 0) it.getLong(idIndex) else -1L
                        break
                    }
                }
            }

            // 2. Create channel if not found
            if (targetChannelId == -1L) {
                val channelValues = ContentValues().apply {
                    put(TvContract.Channels.COLUMN_TYPE, TvContract.Channels.TYPE_PREVIEW)
                    put(TvContract.Channels.COLUMN_DISPLAY_NAME, "VeloxTV Favorites")
                    put(TvContract.Channels.COLUMN_DESCRIPTION, "Your favorite IPTV channels")
                    put(TvContract.Channels.COLUMN_APP_LINK_INTENT_URI, "veloxtv://home")
                }
                val channelUri = resolver.insert(TvContract.Channels.CONTENT_URI, channelValues)
                if (channelUri != null) {
                    targetChannelId = ContentUris.parseId(channelUri)
                    if (targetChannelId != -1L) {
                        TvContract.requestChannelBrowsable(this, targetChannelId)
                    }
                }
            }

            if (targetChannelId == -1L) return

            // 3. Clear existing programs for this channel
            try {
                val programsUri = TvContract.buildPreviewProgramsUriForChannel(targetChannelId)
                resolver.delete(programsUri, null, null)
            } catch (e: Exception) {
                // Ignore if delete fails
            }

            // 4. Insert favorite channels as preview programs (up to 20)
            for (ch in favorites.take(20)) {
                val id = ch["id"]?.toString() ?: continue
                val name = ch["name"]?.toString() ?: "Channel"
                val icon = ch["icon"]?.toString() ?: ""
                val category = ch["category"]?.toString() ?: "Live TV"

                val programValues = ContentValues().apply {
                    put(TvContract.PreviewPrograms.COLUMN_CHANNEL_ID, targetChannelId)
                    put(TvContract.PreviewPrograms.COLUMN_TYPE, TvContract.PreviewPrograms.TYPE_CLIP)
                    put(TvContract.PreviewPrograms.COLUMN_TITLE, name)
                    put(TvContract.PreviewPrograms.COLUMN_DESCRIPTION, category)
                    put(TvContract.PreviewPrograms.COLUMN_INTERNAL_PROVIDER_ID, id)
                    put(TvContract.PreviewPrograms.COLUMN_INTENT_URI, "veloxtv://channel/$id")
                    if (icon.isNotEmpty()) {
                        put(TvContract.PreviewPrograms.COLUMN_POSTER_ART_URI, icon)
                    }
                }

                try {
                    resolver.insert(TvContract.PreviewPrograms.CONTENT_URI, programValues)
                } catch (e: Exception) {
                    // Ignore single program insert failure
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
