import 'package:flutter/services.dart';
import '../models/models.dart';

class TvHomeChannelService {
  static const MethodChannel _channel = MethodChannel('com.veloxtv.app/tv_channel');

  /// Syncs favorite channels to Android TV Home Screen (Leanback Preview Channel)
  static Future<void> syncFavorites(List<ChannelItem> favorites) async {
    try {
      final list = favorites.map((ch) => {
        'id': ch.id,
        'name': ch.name,
        'icon': ch.streamIcon ?? '',
        'category': ch.categoryName ?? 'Live TV',
        'url': ch.streamUrl,
      }).toList();

      await _channel.invokeMethod('syncFavorites', {'channels': list});
    } catch (_) {}
  }

  /// Checks if the app was launched by clicking a favorite channel on Android TV Home
  static Future<String?> getInitialChannelId() async {
    try {
      return await _channel.invokeMethod<String>('getInitialChannelId');
    } catch (_) {
      return null;
    }
  }

  /// Listens for channel selection when app is already open in background
  static void setChannelSelectedListener(Function(String channelId) onSelected) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onChannelSelectedFromHome') {
        final channelId = call.arguments?.toString();
        if (channelId != null && channelId.isNotEmpty) {
          onSelected(channelId);
        }
      }
    });
  }
}
