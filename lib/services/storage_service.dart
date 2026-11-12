import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _keyAccounts = 'velox_accounts';
  static const String _keyActiveAccount = 'velox_active_account';
  static const String _keyFavorites = 'velox_favorites';
  static const String _keyHiddenCategories = 'velox_hidden_categories';
  static const String _keyLockedCategories = 'velox_locked_categories';
  static const String _keyParentalPin = 'velox_parental_pin';
  static const String _keyParentalEnabled = 'velox_parental_enabled';
  static const String _keyResumeProgress = 'velox_resume_progress';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Account
  Future<void> saveActiveAccount(XtreamAccount account) async {
    await _prefs.setString(_keyActiveAccount, jsonEncode(account.toJson()));
  }

  XtreamAccount? getActiveAccount() {
    final raw = _prefs.getString(_keyActiveAccount);
    if (raw == null) return null;
    try {
      return XtreamAccount.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // Favorites
  Set<String> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String channelId) async {
    final favs = getFavorites();
    if (favs.contains(channelId)) {
      favs.remove(channelId);
    } else {
      favs.add(channelId);
    }
    await _prefs.setStringList(_keyFavorites, favs.toList());
  }

  bool isFavorite(String channelId) {
    return getFavorites().contains(channelId);
  }

  // Hidden Categories
  Set<String> getHiddenCategories() {
    return (_prefs.getStringList(_keyHiddenCategories) ?? []).toSet();
  }

  Future<void> toggleCategoryVisibility(String categoryId) async {
    final hidden = getHiddenCategories();
    if (hidden.contains(categoryId)) {
      hidden.remove(categoryId);
    } else {
      hidden.add(categoryId);
    }
    await _prefs.setStringList(_keyHiddenCategories, hidden.toList());
  }

  // Locked Categories
  Set<String> getLockedCategories() {
    return (_prefs.getStringList(_keyLockedCategories) ?? []).toSet();
  }

  Future<void> toggleCategoryLock(String categoryId) async {
    final locked = getLockedCategories();
    if (locked.contains(categoryId)) {
      locked.remove(categoryId);
    } else {
      locked.add(categoryId);
    }
    await _prefs.setStringList(_keyLockedCategories, locked.toList());
  }

  // Parental Control PIN
  bool isParentalControlEnabled() {
    return _prefs.getBool(_keyParentalEnabled) ?? false;
  }

  Future<void> setParentalPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _prefs.setString(_keyParentalPin, hash);
    await _prefs.setBool(_keyParentalEnabled, true);
  }

  bool verifyPin(String pin) {
    if (!isParentalControlEnabled()) return true;
    final savedHash = _prefs.getString(_keyParentalPin);
    if (savedHash == null) return true;
    final inputHash = sha256.convert(utf8.encode(pin)).toString();
    return savedHash == inputHash;
  }

  // Resume History
  int getResumePosition(String streamId) {
    return _prefs.getInt('$_keyResumeProgress$streamId') ?? 0;
  }

  Future<void> saveResumePosition(String streamId, int positionMs) async {
    await _prefs.setInt('$_keyResumeProgress$streamId', positionMs);
  }
}
