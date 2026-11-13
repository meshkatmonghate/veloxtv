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

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
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
    final auth = userInfo['auth']?.toString();
    if (auth != '1') {
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
    try {
      final url = Uri.parse(
          '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_live_categories');

      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((item) {
        return Category(
          id: item['category_id']?.toString() ?? '',
          name: item['category_name']?.toString() ?? 'Unnamed Category',
          streamType: StreamType.live,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChannelItem>> fetchLiveStreams({String? categoryId}) async {
    if (_currentAccount == null) return [];
    try {
      var urlStr =
          '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_live_streams';
      if (categoryId != null && categoryId != 'all') {
        urlStr += '&category_id=$categoryId';
      }

      final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((item) {
        final sId = _parseInt(item['stream_id']) ?? 0;
        final streamUrl =
            '${_currentAccount!.serverUrl}/live/${_currentAccount!.username}/${_currentAccount!.password}/$sId.ts';

        return ChannelItem(
          id: 'xc_live_$sId',
          num: _parseInt(item['num']),
          name: item['name']?.toString() ?? 'Unknown Channel',
          streamId: sId,
          streamIcon: item['stream_icon']?.toString(),
          epgChannelId: item['epg_channel_id']?.toString(),
          categoryId: item['category_id']?.toString() ?? '0',
          streamUrl: streamUrl,
          streamType: StreamType.live,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Category>> fetchVodCategories() async {
    if (_currentAccount == null) return [];
    try {
      final url = Uri.parse(
          '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_vod_categories');

      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((item) {
        return Category(
          id: item['category_id']?.toString() ?? '',
          name: item['category_name']?.toString() ?? 'Unnamed Category',
          streamType: StreamType.movie,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VodItem>> fetchVodStreams({String? categoryId}) async {
    if (_currentAccount == null) return [];
    try {
      var urlStr =
          '${_currentAccount!.serverUrl}/player_api.php?username=${_currentAccount!.username}&password=${_currentAccount!.password}&action=get_vod_streams';
      if (categoryId != null && categoryId != 'all') {
        urlStr += '&category_id=$categoryId';
      }

      final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((item) {
        final sId = _parseInt(item['stream_id']) ?? 0;
        final ext = item['container_extension']?.toString() ?? 'mp4';
        final streamUrl =
            '${_currentAccount!.serverUrl}/movie/${_currentAccount!.username}/${_currentAccount!.password}/$sId.$ext';

        return VodItem(
          streamId: sId,
          name: item['name']?.toString() ?? 'Unknown Movie',
          streamIcon: item['stream_icon']?.toString(),
          rating: _parseDouble(item['rating']),
          categoryId: item['category_id']?.toString() ?? '0',
          containerExtension: ext,
          streamUrl: streamUrl,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String buildLiveHlsUrl(int streamId) {
    if (_currentAccount == null) return '';
    return '${_currentAccount!.serverUrl}/live/${_currentAccount!.username}/${_currentAccount!.password}/$streamId.m3u8';
  }
}
