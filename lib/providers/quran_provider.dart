import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

class QuranProvider extends ChangeNotifier {
  final QuranService _service = QuranService();

  int _currentPage = 1;
  int? _lastReadPage;
  QuranReadingFilter _readingFilter = QuranReadingFilter.original;
  QuranPageFit _pageFit = QuranPageFit.stretchWidth;
  bool _isFullScreen = false;
  bool _isLoading = false;

  final List<QuranBookmark> _bookmarks = [];
  List<QuranSearchResult> _searchResults = [];
  bool _isSearching = false;

  int get currentPage => _currentPage;
  int? get lastReadPage => _lastReadPage;
  QuranReadingFilter get readingFilter => _readingFilter;
  QuranPageFit get pageFit => _pageFit;
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

      final filterIndex = prefs.getInt('quran_reading_filter') ?? 0;
      if (filterIndex >= 0 && filterIndex < QuranReadingFilter.values.length) {
        _readingFilter = QuranReadingFilter.values[filterIndex];
      }

      final fitIndex = prefs.getInt('quran_page_fit') ?? 1;
      if (fitIndex >= 0 && fitIndex < QuranPageFit.values.length) {
        _pageFit = QuranPageFit.values[fitIndex];
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

      if (_lastReadPage != null) {
        _currentPage = _lastReadPage!;
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

  /// Changes reading tone filter
  Future<void> setReadingFilter(QuranReadingFilter filter) async {
    if (_readingFilter != filter) {
      _readingFilter = filter;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_reading_filter', filter.index);
    }
  }

  double _fontSize = 22.0;
  double get fontSize => _fontSize;

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(16.0, 34.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', _fontSize);
  }

  /// No-op: page rendering is now text-based and lightweight
  void precacheAdjacentImages(BuildContext context, int page) {}


  /// Sets page fit mode (contain or stretch width)
  Future<void> setPageFit(QuranPageFit fit) async {
    if (_pageFit != fit) {
      _pageFit = fit;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_fit', fit.index);
    }
  }

  /// Toggles full-screen immersion
  void toggleFullScreen() {
    setFullScreen(!_isFullScreen);
  }

  void setFullScreen(bool value) {
    if (_isFullScreen != value) {
      _isFullScreen = value;
      applySystemUiMode(value);
      notifyListeners();
    }
  }

  /// Applies system UI mode for full screen vs edge to edge
  void applySystemUiMode(bool immersive) {
    if (immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
