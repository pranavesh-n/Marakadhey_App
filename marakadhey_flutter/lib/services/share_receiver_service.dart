import 'dart:async';
import 'package:flutter/services.dart';
import 'date_extractor_service.dart';
import 'url_metadata_service.dart';

class SharedPayload {
  final String url;
  final String? title;
  final DetectedDeadline? detectedDeadline;

  SharedPayload({required this.url, this.title, this.detectedDeadline});
}

class ShareReceiverService {
  static const MethodChannel _channel = MethodChannel('com.marakadhey.app/share');
  static final StreamController<SharedPayload> _streamController =
      StreamController<SharedPayload>.broadcast();

  static SharedPayload? _cachedPayload;

  static Stream<SharedPayload> get sharedStream => _streamController.stream;

  static SharedPayload? get cachedPayload => _cachedPayload;

  static SharedPayload? consumeLatestPayload() {
    final p = _cachedPayload;
    _cachedPayload = null;
    return p;
  }

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedDataReceived') {
        final Map<dynamic, dynamic>? data = call.arguments;
        if (data != null) {
          final payload = await _parseData(data);
          if (payload != null) {
            _cachedPayload = payload;
            _streamController.add(payload);
          }
        }
      }
    });

    // Check initial shared data on app cold-start
    getInitialSharedData();
  }

  static Future<SharedPayload?> getInitialSharedData() async {
    try {
      final Map<dynamic, dynamic>? data =
          await _channel.invokeMethod('getInitialSharedData');
      if (data != null) {
        final payload = await _parseData(data);
        if (payload != null) {
          _cachedPayload = payload;
          _streamController.add(payload);
          // Tell native Android we received it
          await _channel.invokeMethod('clearInitialSharedData');
          return payload;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<SharedPayload?> _parseData(Map<dynamic, dynamic> data) async {
    final String? text = data['text'];
    final String? subject = data['subject'];

    if (text == null && subject == null) return null;

    final fullText = text ?? '';
    // Extract URL using regex
    final urlRegExp = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final match = urlRegExp.firstMatch(fullText);

    String url = '';
    String? title = subject?.trim();

    if (match != null) {
      url = match.group(0) ?? '';
      if (title == null || title.isEmpty) {
        final textBeforeUrl = fullText.replaceAll(url, '').trim();
        if (textBeforeUrl.isNotEmpty) {
          title = textBeforeUrl;
        }
      }
    } else if (fullText.startsWith('http://') || fullText.startsWith('https://')) {
      url = fullText.trim();
    } else {
      title = fullText.trim();
    }

    DetectedDeadline? deadline;

    // Check if deadline is present in the shared fullText
    deadline = DateExtractorService.extractDeadline(fullText);

    // Auto-scrape page title & deadline from URL if needed
    if (url.isNotEmpty) {
      final meta = await UrlMetadataService.fetchMetadata(url);
      if ((title == null || title.isEmpty) && meta.title != null) {
        title = meta.title;
      }
      deadline ??= meta.detectedDeadline;
    }

    if (deadline == null && title != null) {
      deadline = DateExtractorService.extractDeadline(title);
    }

    if (url.isNotEmpty || (title != null && title.isNotEmpty)) {
      return SharedPayload(url: url, title: title, detectedDeadline: deadline);
    }
    return null;
  }
}
