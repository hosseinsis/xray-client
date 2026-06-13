import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2ray_config.dart';

class StorageService {
  static const _configsKey = 'v2ray_configs';
  static const _subsKey = 'v2ray_subscriptions';
  static const _selectedKey = 'selected_config_id';

  // ── Configs ────────────────────────────────────────────────────────────────

  static Future<List<V2RayConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_configsKey) ?? [];
    return raw
        .map((e) => V2RayConfig.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> saveConfigs(List<V2RayConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _configsKey,
      configs.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  static Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_subsKey) ?? [];
    return raw
        .map((e) => Subscription.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> saveSubscriptions(List<Subscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _subsKey,
      subs.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  // ── Selected config ────────────────────────────────────────────────────────

  static Future<String?> loadSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey);
  }

  static Future<void> saveSelectedId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_selectedKey);
    } else {
      await prefs.setString(_selectedKey, id);
    }
  }
}
