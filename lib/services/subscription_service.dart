import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/v2ray_config.dart';
import 'config_parser.dart';

class SubscriptionService {
  /// Fetch subscription URL and return parsed configs
  static Future<List<V2RayConfig>> fetchSubscription(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'V2RayClient/1.0',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    String body = response.body.trim();

    // Try base64 decode first (common subscription format)
    List<V2RayConfig> configs = [];
    try {
      final decoded = utf8.decode(base64.decode(base64.normalize(body)));
      configs = ConfigParser.parseMultiple(decoded);
    } catch (_) {
      // Not base64, try raw
      configs = ConfigParser.parseMultiple(body);
    }

    return configs;
  }
}
