import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;
import '../models/quran_models.dart';
import 'quran_service.dart';

class QuranAudioService extends ChangeNotifier {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    _initAudioPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  final QuranService _quranService = QuranService();

  QuranReciter? _currentReciter;
  int? _currentSurah;
  int? _currentVerse;
  bool _isVerseMode = false;
  bool _autoAdvance = true;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  String? _errorMessage;

  QuranReciter? get currentReciter => _currentReciter;
  int? get currentSurah => _currentSurah;
  int? get currentVerse => _currentVerse;
  bool get isVerseMode => _isVerseMode;
  bool get autoAdvance => _autoAdvance;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped || _playerState == PlayerState.completed;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  void _initAudioPlayer() {
    try {
      _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
    } catch (_) {}

    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _player.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _player.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _position = Duration.zero;
      if (_isVerseMode && _autoAdvance && _currentSurah != null && _currentVerse != null) {
        _handleVerseComplete();
      } else {
        _playerState = PlayerState.completed;
        notifyListeners();
      }
    });
  }

  void _handleVerseComplete() {
    final surah = _currentSurah;
    final verse = _currentVerse;
    if (surah == null || verse == null) {
      _playerState = PlayerState.completed;
      notifyListeners();
      return;
    }

    final totalVerses = quran.getVerseCount(surah);
    if (verse < totalVerses) {
      playVerse(
        surahNumber: surah,
        verseNumber: verse + 1,
        reciter: _currentReciter,
        autoAdvance: true,
      );
    } else if (surah < 114) {
      playVerse(
        surahNumber: surah + 1,
        verseNumber: 1,
        reciter: _currentReciter,
        autoAdvance: true,
      );
    } else {
      _playerState = PlayerState.completed;
      notifyListeners();
    }
  }

  /// Plays a specific verse with EveryAyah CDN
  Future<void> playVerse({
    required int surahNumber,
    required int verseNumber,
    QuranReciter? reciter,
    bool autoAdvance = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _isVerseMode = true;
      _autoAdvance = autoAdvance;
      _currentSurah = surahNumber;
      _currentVerse = verseNumber;
      notifyListeners();

      if (reciter != null) {
        _currentReciter = reciter;
      } else if (_currentReciter == null) {
        final reciters = await _quranService.getReciters();
        if (reciters.isNotEmpty) {
          _currentReciter = reciters.first;
        }
      }

      if (_currentReciter == null) {
        _isLoading = false;
        _errorMessage = 'لم يتم العثور على قارئ';
        notifyListeners();
        return;
      }

      final audioUrl = _quranService.getVerseAudioUrl(
        reciterId: _currentReciter!.id,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      await _player.stop();
      await _player.play(UrlSource(audioUrl));
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تشغيل تلاوة الآية: $e';
      debugPrint('Error playing Quran verse audio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Plays a full surah
  Future<void> playSurah({required int surahNumber, QuranReciter? reciter}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _isVerseMode = false;
      _currentVerse = null;
      notifyListeners();

      if (reciter != null) {
        _currentReciter = reciter;
      } else if (_currentReciter == null) {
        final reciters = await _quranService.getReciters();
        if (reciters.isNotEmpty) {
          _currentReciter = reciters.first;
        }
      }

      if (_currentReciter == null) {
        _isLoading = false;
        _errorMessage = 'لم يتم العثور على قارئ';
        notifyListeners();
        return;
      }

      _currentSurah = surahNumber;
      final audioUrl = _quranService.getAudioUrl(_currentReciter!.url, surahNumber);

      await _player.stop();
      await _player.play(UrlSource(audioUrl));
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تشغيل التلاوة: $e';
      debugPrint('Error playing Quran audio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> nextVerse() async {
    if (_currentSurah == null) return;
    final curVerse = _currentVerse ?? 1;
    final totalVerses = quran.getVerseCount(_currentSurah!);

    if (curVerse < totalVerses) {
      await playVerse(
        surahNumber: _currentSurah!,
        verseNumber: curVerse + 1,
        reciter: _currentReciter,
        autoAdvance: _autoAdvance,
      );
    } else if (_currentSurah! < 114) {
      await playVerse(
        surahNumber: _currentSurah! + 1,
        verseNumber: 1,
        reciter: _currentReciter,
        autoAdvance: _autoAdvance,
      );
    }
  }

  Future<void> previousVerse() async {
    if (_currentSurah == null) return;
    final curVerse = _currentVerse ?? 1;

    if (curVerse > 1) {
      await playVerse(
        surahNumber: _currentSurah!,
        verseNumber: curVerse - 1,
        reciter: _currentReciter,
        autoAdvance: _autoAdvance,
      );
    } else if (_currentSurah! > 1) {
      final prevSurah = _currentSurah! - 1;
      final prevTotal = quran.getVerseCount(prevSurah);
      await playVerse(
        surahNumber: prevSurah,
        verseNumber: prevTotal,
        reciter: _currentReciter,
        autoAdvance: _autoAdvance,
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (isPaused) {
      await resume();
    } else if (_isVerseMode && _currentSurah != null && _currentVerse != null) {
      await playVerse(
        surahNumber: _currentSurah!,
        verseNumber: _currentVerse!,
        reciter: _currentReciter,
        autoAdvance: _autoAdvance,
      );
    } else if (_currentSurah != null) {
      await playSurah(surahNumber: _currentSurah!, reciter: _currentReciter);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSurah = null;
    _currentVerse = null;
    _isVerseMode = false;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

