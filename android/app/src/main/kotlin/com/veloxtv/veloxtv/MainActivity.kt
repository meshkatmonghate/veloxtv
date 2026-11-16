package com.veloxtv.veloxtv

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import androidx.tvprovider.media.tv.PreviewChannel
import androidx.tvprovider.media.tv.PreviewChannelHelper
import androidx.tvprovider.media.tv.PreviewProgram
import androidx.tvprovider.media.tv.TvContractCompat
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
            val channelHelper = PreviewChannelHelper(this)
            val existingChannels = channelHelper.allChannels
            var myChannel = existingChannels.find { it.displayName == "VeloxTV Favorites" }

            val targetChannelId: Long
            if (myChannel == null) {
                val newChannel = PreviewChannel.Builder()
                    .setType(TvContractCompat.Channels.TYPE_PREVIEW)
                    .setDisplayName("VeloxTV Favorites")
                    .setDescription("Your favorite IPTV channels")
                    .setAppLinkIntentUri(Uri.parse("veloxtv://home"))
                    .build()
                val publishedUri = channelHelper.publishChannel(newChannel)
                targetChannelId = TvContractCompat.parseChannelId(publishedUri)
                if (targetChannelId != -1L) {
                    TvContractCompat.requestChannelBrowsable(this, targetChannelId)
                }
            } else {
                targetChannelId = myChannel.id
            }

            if (targetChannelId == -1L) return

            // Remove existing programs in this channel to refresh with latest favorites
            val existingPrograms = channelHelper.getProgramsForChannel(targetChannelId)
            for (prog in existingPrograms) {
                try {
                    channelHelper.deletePreviewProgram(prog.id)
                } catch (_: Exception) {}
            }

            // Add up to 20 favorite channels as program cards
            for (ch in favorites.take(20)) {
                val id = ch["id"]?.toString() ?: continue
                val name = ch["name"]?.toString() ?: "Channel"
                val icon = ch["icon"]?.toString() ?: ""
                val category = ch["category"]?.toString() ?: "Live TV"

                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("veloxtv://channel/$id")
                    putExtra("launch_channel_id", id)
                }

                val programBuilder = PreviewProgram.Builder()
                    .setChannelId(targetChannelId)
                    .setType(TvContractCompat.PreviewPrograms.TYPE_CLIP)
                    .setTitle(name)
                    .setDescription(category)
                    .setInternalProviderId(id)
                    .setIntent(launchIntent)

                if (icon.isNotEmpty()) {
                    try {
                        programBuilder.setPosterArtUri(Uri.parse(icon))
                    } catch (_: Exception) {}
                }

                channelHelper.publishPreviewProgram(programBuilder.build())
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
