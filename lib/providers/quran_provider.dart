import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

enum QuranThemeType {
  cream, // Warm Mushaf Paper (Default)
  sepia, // Classic Vintage Paper
  dark,  // Night Reading Mode
}

class QuranProvider extends ChangeNotifier {
  final QuranService _service = QuranService();

  int _currentPage = 1;
  int? _lastReadPage;
  double _fontSize = 24.0;
  QuranThemeType _themeType = QuranThemeType.cream;
  bool _isFullScreen = false;
  bool _isLoading = false;

  final List<QuranBookmark> _bookmarks = [];
  List<QuranSearchResult> _searchResults = [];
  bool _isSearching = false;

  int get currentPage => _currentPage;
  int? get lastReadPage => _lastReadPage;
  double get fontSize => _fontSize;
  QuranThemeType get themeType => _themeType;
  bool get isFullScreen => _isFullScreen;
  bool get isLoading => _isLoading;
  List<QuranBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<QuranSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  QuranProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _lastReadPage = prefs.getInt('quran_last_read_page') ?? 1;
      _fontSize = prefs.getDouble('quran_font_size') ?? 24.0;

      final themeIndex = prefs.getInt('quran_theme_type') ?? 0;
      if (themeIndex >= 0 && themeIndex < QuranThemeType.values.length) {
        _themeType = QuranThemeType.values[themeIndex];
      }

      // Load bookmarks
      final bookmarksJson = prefs.getStringList('quran_bookmarks_list');
      if (bookmarksJson != null) {
        _bookmarks.clear();
        for (final item in bookmarksJson) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            _bookmarks.add(QuranBookmark.fromJson(map));
          } catch (_) {}
        }
      }

      // Pre-warm initial pages
      if (_lastReadPage != null) {
        _currentPage = _lastReadPage!;
        _service.prefetchPages(_currentPage, radius: 3);
      }
    } catch (e) {
      debugPrint('Error loading Quran preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets current reading page and auto-saves as last read
  void setCurrentPage(int page, {bool autoSave = true}) {
    if (page < 1) page = 1;
    if (page > 604) page = 604;

    if (_currentPage != page) {
      _currentPage = page;
      _service.prefetchPages(page, radius: 2);
      if (autoSave) {
        saveLastReadPage(page);
      }
      notifyListeners();
    }
  }

  /// Persists last read page
  Future<void> saveLastReadPage(int page) async {
    _lastReadPage = page;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_last_read_page', page);
  }

  /// Changes font size dynamically
  Future<void> setFontSize(double size) async {
    final clamped = size.clamp(16.0, 42.0);
    if (_fontSize != clamped) {
      _fontSize = clamped;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('quran_font_size', clamped);
    }
  }

  /// Changes theme mode
  Future<void> setThemeType(QuranThemeType type) async {
    if (_themeType != type) {
      _themeType = type;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_theme_type', type.index);
    }
  }

  /// Toggles full-screen immersion
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void setFullScreen(bool value) {
    if (_isFullScreen != value) {
      _isFullScreen = value;
      notifyListeners();
    }
  }

  /// Checks if a page is bookmarked
  bool isPageBookmarked(int page) {
    return _bookmarks.any((b) => b.pageNumber == page);
  }

  /// Toggles bookmark for current page
  Future<bool> toggleBookmark(int page) async {
    final existingIndex = _bookmarks.indexWhere((b) => b.pageNumber == page);
    bool added = false;

    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      added = false;
    } else {
      final pageData = _service.getPageDataSync(page);
      _bookmarks.insert(
        0,
        QuranBookmark(
          pageNumber: page,
          surahName: pageData.primarySurahName,
          juzNumber: pageData.juzNumber,
          createdAt: DateTime.now(),
        ),
      );
      added = true;
    }

    notifyListeners();
    await _saveBookmarks();
    return added;
  }

  Future<void> removeBookmark(int page) async {
    _bookmarks.removeWhere((b) => b.pageNumber == page);
    notifyListeners();
    await _saveBookmarks();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _bookmarks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('quran_bookmarks_list', jsonList);
  }

  /// Performs full-text search across Quran
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = await _service.searchVerses(query);
    _searchResults = results;
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
