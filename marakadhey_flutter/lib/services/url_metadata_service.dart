import 'dart:convert';
import 'package:http/http.dart' as http;

class UrlMetadataService {
  /// Fetch the webpage title by inspecting HTML or via CORS/proxy fallback
  static Future<String?> fetchTitle(String url) async {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return null;
    }

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
        final title = _extractTitle(response.body);
        if (title != null && title.isNotEmpty) return title;
      }
    } catch (_) {
      // Fall back to public JSON scraper proxy
    }

    try {
      // 2. CORS Proxy Fallback
      final proxyUri = Uri.parse('https://api.allorigins.win/get?url=${Uri.encodeComponent(cleanUrl)}');
      final proxyRes = await http.get(proxyUri).timeout(const Duration(seconds: 6));
      if (proxyRes.statusCode == 200) {
        final data = json.decode(proxyRes.body) as Map<String, dynamic>;
        final contents = data['contents'] as String?;
        if (contents != null) {
          final title = _extractTitle(contents);
          if (title != null && title.isNotEmpty) return title;
        }
      }
    } catch (_) {}

    return null;
  }

  static String? _extractTitle(String html) {
    final titleRegExp = RegExp(r'<title[^>]*>([^<]+)<\/title>', caseSensitive: false);
    final match = titleRegExp.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      String raw = match.group(1) ?? '';
      // Decode HTML entities
      raw = raw
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'")
          .replaceAll('&#39;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();
      return raw;
    }
    return null;
  }
}
