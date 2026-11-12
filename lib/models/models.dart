enum StreamType { live, movie, series }

class Category {
  final String id;
  final String name;
  bool isHidden;
  bool isLocked;
  final StreamType streamType;

  Category({
    required this.id,
    required this.name,
    this.isHidden = false,
    this.isLocked = false,
    required this.streamType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHidden': isHidden,
        'isLocked': isLocked,
        'streamType': streamType.name,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        isHidden: json['isHidden'] ?? false,
        isLocked: json['isLocked'] ?? false,
        streamType: StreamType.values.firstWhere(
          (e) => e.name == json['streamType'],
          orElse: () => StreamType.live,
        ),
      );
}

class ChannelItem {
  final String id;
  final int? num;
  final String name;
  final int? streamId;
  final String? streamIcon;
  final String? epgChannelId;
  final String categoryId;
  final String? categoryName;
  final String streamUrl;
  bool isFavorite;
  bool isLocked;
  final StreamType streamType;

  ChannelItem({
    required this.id,
    this.num,
    required this.name,
    this.streamId,
    this.streamIcon,
    this.epgChannelId,
    required this.categoryId,
    this.categoryName,
    required this.streamUrl,
    this.isFavorite = false,
    this.isLocked = false,
    this.streamType = StreamType.live,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'num': num,
        'name': name,
        'streamId': streamId,
        'streamIcon': streamIcon,
        'epgChannelId': epgChannelId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'streamUrl': streamUrl,
        'isFavorite': isFavorite,
        'isLocked': isLocked,
        'streamType': streamType.name,
      };

  factory ChannelItem.fromJson(Map<String, dynamic> json) => ChannelItem(
        id: json['id'] ?? '',
        num: json['num'],
        name: json['name'] ?? 'Unknown',
        streamId: json['streamId'],
        streamIcon: json['streamIcon'],
        epgChannelId: json['epgChannelId'],
        categoryId: json['categoryId'] ?? '0',
        categoryName: json['categoryName'],
        streamUrl: json['streamUrl'] ?? '',
        isFavorite: json['isFavorite'] ?? false,
        isLocked: json['isLocked'] ?? false,
        streamType: StreamType.values.firstWhere(
          (e) => e.name == json['streamType'],
          orElse: () => StreamType.live,
        ),
      );
}

class VodItem {
  final int streamId;
  final String name;
  final String? streamIcon;
  final double? rating;
  final String categoryId;
  final String containerExtension;
  final String streamUrl;
  int resumePositionMs;
  int durationMs;
  bool isFavorite;

  VodItem({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.rating,
    required this.categoryId,
    required this.containerExtension,
    required this.streamUrl,
    this.resumePositionMs = 0,
    this.durationMs = 0,
    this.isFavorite = false,
  });

  double get watchProgress =>
      durationMs > 0 ? (resumePositionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'streamId': streamId,
        'name': name,
        'streamIcon': streamIcon,
        'rating': rating,
        'categoryId': categoryId,
        'containerExtension': containerExtension,
        'streamUrl': streamUrl,
        'resumePositionMs': resumePositionMs,
        'durationMs': durationMs,
        'isFavorite': isFavorite,
      };

  factory VodItem.fromJson(Map<String, dynamic> json) => VodItem(
        streamId: json['streamId'] ?? 0,
        name: json['name'] ?? '',
        streamIcon: json['streamIcon'],
        rating: (json['rating'] as num?)?.toDouble(),
        categoryId: json['categoryId'] ?? '0',
        containerExtension: json['containerExtension'] ?? 'mp4',
        streamUrl: json['streamUrl'] ?? '',
        resumePositionMs: json['resumePositionMs'] ?? 0,
        durationMs: json['durationMs'] ?? 0,
        isFavorite: json['isFavorite'] ?? false,
      );
}

class RecordingTask {
  final String id;
  final String channelName;
  final String streamUrl;
  final String filePath;
  final DateTime startTime;
  DateTime? endTime;
  int totalBytes;
  bool isActive;

  RecordingTask({
    required this.id,
    required this.channelName,
    required this.streamUrl,
    required this.filePath,
    required this.startTime,
    this.endTime,
    this.totalBytes = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelName': channelName,
        'streamUrl': streamUrl,
        'filePath': filePath,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'totalBytes': totalBytes,
        'isActive': isActive,
      };

  factory RecordingTask.fromJson(Map<String, dynamic> json) => RecordingTask(
        id: json['id'],
        channelName: json['channelName'],
        streamUrl: json['streamUrl'],
        filePath: json['filePath'],
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        totalBytes: json['totalBytes'] ?? 0,
        isActive: json['isActive'] ?? false,
      );
}

class XtreamAccount {
  final String serverUrl;
  final String username;
  final String password;
  final String? expireDate;
  final String? status;

  XtreamAccount({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.expireDate,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'expireDate': expireDate,
        'status': status,
      };

  factory XtreamAccount.fromJson(Map<String, dynamic> json) => XtreamAccount(
        serverUrl: json['serverUrl'] ?? '',
        username: json['username'] ?? '',
        password: json['password'] ?? '',
        expireDate: json['expireDate'],
        status: json['status'],
      );
}
