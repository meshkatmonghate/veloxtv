import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class M3uResult {
  final List<ChannelItem> channels;
  final List<Category> categories;

  M3uResult({required this.channels, required this.categories});
}

class M3uService {
  Future<M3uResult> parseUrl(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Failed to download M3U playlist: HTTP ${response.statusCode}');
    }
    return parseContent(response.body);
  }

  M3uResult parseContent(String content) {
    final lines = const LineSplitter().convert(content);
    final channels = <ChannelItem>[];
    final categoryMap = <String, Category>{};

    Map<String, String>? currentAttrs;
    String currentName = '';

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final parsed = _parseExtinf(line);
        currentAttrs = parsed.attrs;
        currentName = parsed.name;
      } else if (!line.startsWith('#')) {
        // Stream URL
        if (currentAttrs != null) {
          final groupTitle = currentAttrs['group-title'] ?? 'Other / Uncategorized';
          if (!categoryMap.containsKey(groupTitle)) {
            categoryMap[groupTitle] = Category(
              id: groupTitle,
              name: groupTitle,
              streamType: StreamType.live,
            );
          }

          final channelId = 'm3u_${channels.length + 1}';
          channels.add(ChannelItem(
            id: channelId,
            name: currentName.isNotEmpty ? currentName : 'Unnamed Stream',
            streamIcon: currentAttrs['tvg-logo'],
            epgChannelId: currentAttrs['tvg-id'],
            categoryId: groupTitle,
            categoryName: groupTitle,
            streamUrl: line,
            streamType: StreamType.live,
          ));

          currentAttrs = null;
          currentName = '';
        }
      }
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return M3uResult(channels: channels, categories: categories);
  }

  _ExtinfResult _parseExtinf(String line) {
    final commaIndex = line.lastIndexOf(',');
    String channelName = '';
    final attrs = <String, String>{};

    if (commaIndex != -1) {
      channelName = line.substring(commaIndex + 1).trim();
      final meta = line.substring(8, commaIndex); // After #EXTINF:

      final regExp = RegExp(r'([a-zA-Z0-9_-]+)="([^"]*)"');
      final matches = regExp.allMatches(meta);
      for (final match in matches) {
        final key = match.group(1)?.toLowerCase();
        final value = match.group(2);
        if (key != null && value != null) {
          attrs[key] = value;
        }
      }
    }

    return _ExtinfResult(attrs: attrs, name: channelName);
  }
}

class _ExtinfResult {
  final Map<String, String> attrs;
  final String name;

  _ExtinfResult({required this.attrs, required this.name});
}
