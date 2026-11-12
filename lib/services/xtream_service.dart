import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class XtreamService {
  XtreamAccount? _currentAccount;

  void setAccount(XtreamAccount account) {
    _currentAccount = account;
  }

  XtreamAccount? get currentAccount => _currentAccount;

  String _cleanUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    return clean;
  }

  Future<XtreamAccount> authenticate({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final base = _cleanUrl(serverUrl);
    final url = Uri.parse('$base/player_api.php?username=$username&password=$password');

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! Map || !data.containsKey('user_info')) {
      throw Exception('Invalid Xtream Codes credentials or server error');
    }

    final userInfo = data['user_info'];
    if (userInfo['auth'] != 1) {
      throw Exception('Authentication failed: Invalid username or password');
    }

    final account = XtreamAccount(
      serverUrl: base,
      username: username,
      password: password,
      expireDate: userInfo['exp_date']?.toString(),
      status: userInfo['status']?.toString(),
    );

    _currentAccount = account;
    return account;
  }

  Future<List<Category>> fetchLiveCategories() async {
    if (_currentAccount == null) return [];
    final url = Uri.parse(
        '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_live_categories');

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((item) {
      return Category(
        id: item['category_id'].toString(),
        name: item['category_name'].toString(),
        streamType: StreamType.live,
      );
    }).toList();
  }

  Future<List<ChannelItem>> fetchLiveStreams({String? categoryId}) async {
    if (_currentAccount == null) return [];
    var urlStr =
        '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_live_streams';
    if (categoryId != null && categoryId != 'all') {
      urlStr += '&category_id=$categoryId';
    }

    final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((item) {
      final sId = item['stream_id'];
      final streamUrl =
          '${_currentAccount!.serverUrl}/live/${_currentAccount!.username}/${_currentAccount!.password}/$sId.ts';

      return ChannelItem(
        id: 'xc_live_$sId',
        num: item['num'] != null ? int.tryParse(item['num'].toString()) : null,
        name: item['name'] ?? 'Unknown Channel',
        streamId: sId is int ? sId : int.tryParse(sId.toString()),
        streamIcon: item['stream_icon'],
        epgChannelId: item['epg_channel_id'],
        categoryId: item['category_id']?.toString() ?? '0',
        streamUrl: streamUrl,
        streamType: StreamType.live,
      );
    }).toList();
  }

  Future<List<Category>> fetchVodCategories() async {
    if (_currentAccount == null) return [];
    final url = Uri.parse(
        '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_vod_categories');

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((item) {
      return Category(
        id: item['category_id'].toString(),
        name: item['category_name'].toString(),
        streamType: StreamType.movie,
      );
    }).toList();
  }

  Future<List<VodItem>> fetchVodStreams({String? categoryId}) async {
    if (_currentAccount == null) return [];
    var urlStr =
        '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_vod_streams';
    if (categoryId != null && categoryId != 'all') {
      urlStr += '&category_id=$categoryId';
    }

    final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((item) {
      final sId = item['stream_id'] is int ? item['stream_id'] : int.parse(item['stream_id'].toString());
      final ext = item['container_extension']?.toString() ?? 'mp4';
      final streamUrl =
          '${_currentAccount!.serverUrl}/movie/${_currentAccount!.username}/${_currentAccount!.password}/$sId.$ext';

      return VodItem(
        streamId: sId,
        name: item['name'] ?? 'Unknown Movie',
        streamIcon: item['stream_icon'],
        rating: (item['rating'] as num?)?.toDouble(),
        categoryId: item['category_id']?.toString() ?? '0',
        containerExtension: ext,
        streamUrl: streamUrl,
      );
    }).toList();
  }

  String buildLiveHlsUrl(int streamId) {
    if (_currentAccount == null) return '';
    return '${_currentAccount!.serverUrl}/live/${_currentAccount!.username}/${_currentAccount!.password}/$streamId.m3u8';
  }
}
