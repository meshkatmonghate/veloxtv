import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/xtream_service.dart';
import '../services/m3u_service.dart';
import '../services/recording_service.dart';

class AppState extends ChangeNotifier {
  final StorageService storageService;
  final XtreamService xtreamService;
  final M3uService m3uService;
  final RecordingService recordingService;

  AppState({
    required this.storageService,
    required this.xtreamService,
    required this.m3uService,
    required this.recordingService,
  });

  bool _isLoading = false;
  String? _errorMessage;

  List<Category> _liveCategories = [];
  List<ChannelItem> _channels = [];
  List<Category> _vodCategories = [];
  List<VodItem> _vodMovies = [];

  // Memory caches for on-demand loading (prevents server 512 overload)
  final Map<String, List<ChannelItem>> _categoryChannelCache = {};
  final Map<String, List<VodItem>> _categoryVodCache = {};

  String? _selectedLiveCategoryId;
  String? _selectedVodCategoryId;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Category> get liveCategories => _liveCategories;
  List<Category> get vodCategories => _vodCategories;
  String? get selectedLiveCategoryId => _selectedLiveCategoryId;
  String? get selectedVodCategoryId => _selectedVodCategoryId;
  String get searchQuery => _searchQuery;

  // Filtered categories (respects hidden categories)
  List<Category> get visibleLiveCategories {
    final hidden = storageService.getHiddenCategories();
    return _liveCategories.where((c) => !hidden.contains(c.id)).toList();
  }

  // Filtered channels
  List<ChannelItem> get filteredChannels {
    final hiddenCats = storageService.getHiddenCategories();
    return _channels.where((ch) {
      if (hiddenCats.contains(ch.categoryId)) return false;

      if (_selectedLiveCategoryId != null && _selectedLiveCategoryId != 'all') {
        if (ch.categoryId != _selectedLiveCategoryId) return false;
      }

      if (_searchQuery.isNotEmpty) {
        if (!ch.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Favorites
  List<ChannelItem> get favoriteChannels {
    final favIds = storageService.getFavorites();
    return _channels.where((ch) => favIds.contains(ch.id)).toList();
  }

  // Movies
  List<VodItem> get filteredMovies {
    final hiddenCats = storageService.getHiddenCategories();
    return _vodMovies.where((m) {
      if (hiddenCats.contains(m.categoryId)) return false;
      if (_selectedVodCategoryId != null && _selectedVodCategoryId != 'all') {
        if (m.categoryId != _selectedVodCategoryId) return false;
      }
      if (_searchQuery.isNotEmpty) {
        if (!m.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectLiveCategory(String? categoryId) {
    _selectedLiveCategoryId = categoryId;
    notifyListeners();
    loadChannelsForCategory(categoryId);
  }

  void selectVodCategory(String? categoryId) {
    _selectedVodCategoryId = categoryId;
    notifyListeners();
    loadMoviesForCategory(categoryId);
  }

  Future<void> loadChannelsForCategory(String? categoryId) async {
    if (categoryId == null) return;
    if (_categoryChannelCache.containsKey(categoryId)) {
      _channels = _categoryChannelCache[categoryId]!;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final channels = await xtreamService.fetchLiveStreams(
        categoryId: categoryId == 'all' ? null : categoryId,
      );
      _categoryChannelCache[categoryId] = channels;
      _channels = channels;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoviesForCategory(String? categoryId) async {
    if (categoryId == null) return;
    if (_categoryVodCache.containsKey(categoryId)) {
      _vodMovies = _categoryVodCache[categoryId]!;
      notifyListeners();
      return;
    }

    try {
      final movies = await xtreamService.fetchVodStreams(
        categoryId: categoryId == 'all' ? null : categoryId,
      );
      _categoryVodCache[categoryId] = movies;
      _vodMovies = movies;
      notifyListeners();
    } catch (_) {}
  }

  // Xtream Codes Login
  Future<bool> loginXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await xtreamService.authenticate(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      await storageService.saveActiveAccount(account);

      await loadXtreamData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Import M3U
  Future<bool> importM3uUrl(String url) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await m3uService.parseUrl(url);
      _channels = result.channels;
      _liveCategories = result.categories;
      _selectedLiveCategoryId = _liveCategories.isNotEmpty ? _liveCategories.first.id : null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadXtreamData() async {
    _liveCategories = await xtreamService.fetchLiveCategories();
    _vodCategories = await xtreamService.fetchVodCategories();

    if (_liveCategories.isNotEmpty) {
      _selectedLiveCategoryId = _liveCategories.first.id;
      await loadChannelsForCategory(_selectedLiveCategoryId);
    } else {
      _channels = await xtreamService.fetchLiveStreams();
    }

    if (_vodCategories.isNotEmpty) {
      _selectedVodCategoryId = _vodCategories.first.id;
      await loadMoviesForCategory(_selectedVodCategoryId);
    }
    notifyListeners();
  }

  // Favorites Toggle
  Future<void> toggleFavorite(ChannelItem channel) async {
    await storageService.toggleFavorite(channel.id);
    channel.isFavorite = !channel.isFavorite;
    notifyListeners();
  }

  // Category Hide/Unhide
  Future<void> toggleCategoryVisibility(String categoryId) async {
    await storageService.toggleCategoryVisibility(categoryId);
    notifyListeners();
  }

  // Category Lock/Unlock
  Future<void> toggleCategoryLock(String categoryId) async {
    await storageService.toggleCategoryLock(categoryId);
    notifyListeners();
  }

  bool isCategoryLocked(String categoryId, String categoryName) {
    if (!storageService.isParentalControlEnabled()) return false;
    if (storageService.getLockedCategories().contains(categoryId)) return true;

    final lower = categoryName.toLowerCase();
    if (lower.contains('adult') ||
        lower.contains('xxx') ||
        lower.contains('18+') ||
        lower.contains('porn') ||
        lower.contains('erotic')) {
      return true;
    }
    return false;
  }
}
