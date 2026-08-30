import 'dart:convert';
import 'package:http/http.dart' as http;
import 'date_extractor_service.dart';

class UrlScrapedData {
  final String? title;
  final String? snippet;
  final DetectedDeadline? detectedDeadline;

  UrlScrapedData({
    this.title,
    this.snippet,
    this.detectedDeadline,
  });
}

class UrlMetadataService {
  /// Fetch both the webpage title and any auto-detected deadline dates
  static Future<UrlScrapedData> fetchMetadata(String url) async {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return UrlScrapedData();
    }

    String? htmlContent;

    try {
      // 1. Direct HTTP request
      final uri = Uri.parse(cleanUrl);
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        htmlContent = response.body;
      }
    } catch (_) {
      // Fall back to public JSON scraper proxy
    }

    if (htmlContent == null) {
      try {
        // 2. CORS Proxy Fallback
        final proxyUri = Uri.parse('https://api.allorigins.win/get?url=${Uri.encodeComponent(cleanUrl)}');
        final proxyRes = await http.get(proxyUri).timeout(const Duration(seconds: 6));
        if (proxyRes.statusCode == 200) {
          final data = json.decode(proxyRes.body) as Map<String, dynamic>;
          htmlContent = data['contents'] as String?;
        }
      } catch (_) {}
    }

    if (htmlContent != null) {
      final title = _extractTitle(htmlContent);
      final snippet = _extractSnippet(htmlContent);
      
      // Attempt deadline detection from Title, meta tags, and body text
      DetectedDeadline? deadline;
      if (title != null) {
        deadline = DateExtractorService.extractDeadline(title);
      }
      if (deadline == null && snippet != null) {
        deadline = DateExtractorService.extractDeadline(snippet);
      }
      if (deadline == null) {
        deadline = DateExtractorService.extractDeadline(htmlContent);
      }

      return UrlScrapedData(
        title: title,
        snippet: snippet,
        detectedDeadline: deadline,
      );
    }

    return UrlScrapedData();
  }

  /// Fetch the webpage title by inspecting HTML or via CORS/proxy fallback
  static Future<String?> fetchTitle(String url) async {
    final result = await fetchMetadata(url);
    return result.title;
  }

  static String? _extractTitle(String html) {
    final titleRegExp = RegExp(r'<title[^>]*>([^<]+)<\/title>', caseSensitive: false);
    final match = titleRegExp.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      String raw = match.group(1) ?? '';
      return _cleanHtmlText(raw);
    }
    return null;
  }

  static String? _extractSnippet(String html) {
    // Extract description from meta tags or main body text
    final metaDescRegExp = RegExp(
      r'''<meta[^>]+(?:name|property)=["'](?:description|og:description)["'][^>]+content=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final metaMatch = metaDescRegExp.firstMatch(html);
    if (metaMatch != null && metaMatch.groupCount >= 1) {
      return _cleanHtmlText(metaMatch.group(1) ?? '');
    }

    // Strip tags to get readable text (first 3000 chars)
    final textOnly = html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return textOnly.length > 3000 ? textOnly.substring(0, 3000) : textOnly;
  }

  static String _cleanHtmlText(String raw) {
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
