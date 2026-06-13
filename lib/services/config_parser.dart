import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/v2ray_config.dart';

const _uuid = Uuid();

class ConfigParser {
  /// Parse a single config link (vmess://, vless://, trojan://, ss://)
  static V2RayConfig? parse(String link) {
    link = link.trim();
    if (link.startsWith('vmess://')) return _parseVmess(link);
    if (link.startsWith('vless://')) return _parseVless(link);
    if (link.startsWith('trojan://')) return _parseTrojan(link);
    if (link.startsWith('ss://')) return _parseShadowsocks(link);
    return null;
  }

  /// Parse multiple lines, return valid configs
  static List<V2RayConfig> parseMultiple(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map(parse)
        .whereType<V2RayConfig>()
        .toList();
  }

  // ── VMess ──────────────────────────────────────────────────────────────────
  static V2RayConfig? _parseVmess(String link) {
    try {
      final b64 = link.substring('vmess://'.length);
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(b64))),
      ) as Map<String, dynamic>;

      final address = json['add']?.toString() ?? '';
      final port = int.tryParse(json['port']?.toString() ?? '0') ?? 0;
      final name = _decodeName(json['ps']?.toString() ?? address);

      return V2RayConfig(
        id: _uuid.v4(),
        name: name,
        address: address,
        port: port,
        type: ConfigType.vmess,
        rawLink: link,
        extra: {
          'id': json['id'],
          'alterId': json['aid'],
          'network': json['net'] ?? 'tcp',
          'tls': json['tls'] ?? '',
          'path': json['path'] ?? '',
          'host': json['host'] ?? '',
          'scy': json['scy'] ?? 'auto',
        },
      );
    } catch (_) {
      return null;
    }
  }

  // ── VLESS ──────────────────────────────────────────────────────────────────
  static V2RayConfig? _parseVless(String link) {
    try {
      final uri = Uri.parse(link);
      final address = uri.host;
      final port = uri.port;
      final name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : address);

      return V2RayConfig(
        id: _uuid.v4(),
        name: name,
        address: address,
        port: port,
        type: ConfigType.vless,
        rawLink: link,
        extra: {
          'uuid': uri.userInfo,
          'encryption': uri.queryParameters['encryption'] ?? 'none',
          'type': uri.queryParameters['type'] ?? 'tcp',
          'security': uri.queryParameters['security'] ?? 'none',
          'path': uri.queryParameters['path'] ?? '',
          'host': uri.queryParameters['host'] ?? '',
          'sni': uri.queryParameters['sni'] ?? '',
          'flow': uri.queryParameters['flow'] ?? '',
          'fp': uri.queryParameters['fp'] ?? '',
          'pbk': uri.queryParameters['pbk'] ?? '',
          'sid': uri.queryParameters['sid'] ?? '',
          'spx': uri.queryParameters['spx'] ?? '',
          'headerType': uri.queryParameters['headerType'] ?? '',
        },
      );
    } catch (_) {
      return null;
    }
  }

  // ── Trojan ─────────────────────────────────────────────────────────────────
  static V2RayConfig? _parseTrojan(String link) {
    try {
      final uri = Uri.parse(link);
      final address = uri.host;
      final port = uri.port;
      final name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : address);

      return V2RayConfig(
        id: _uuid.v4(),
        name: name,
        address: address,
        port: port,
        type: ConfigType.trojan,
        rawLink: link,
        extra: {
          'password': uri.userInfo,
          'type': uri.queryParameters['type'] ?? 'tcp',
          'security': uri.queryParameters['security'] ?? 'tls',
          'sni': uri.queryParameters['sni'] ?? address,
          'path': uri.queryParameters['path'] ?? '',
          'host': uri.queryParameters['host'] ?? '',
          'fp': uri.queryParameters['fp'] ?? '',
          'alpn': uri.queryParameters['alpn'] ?? '',
        },
      );
    } catch (_) {
      return null;
    }
  }

  // ── Shadowsocks ────────────────────────────────────────────────────────────
  static V2RayConfig? _parseShadowsocks(String link) {
    try {
      // ss://BASE64(method:password)@host:port#name
      // or ss://BASE64(method:password@host:port)#name
      String raw = link.substring('ss://'.length);
      String name = '';

      if (raw.contains('#')) {
        final parts = raw.split('#');
        raw = parts[0];
        name = Uri.decodeComponent(parts.sublist(1).join('#'));
      }

      String method, password, address;
      int port;

      if (raw.contains('@')) {
        final atIdx = raw.lastIndexOf('@');
        final credB64 = raw.substring(0, atIdx);
        final hostPart = raw.substring(atIdx + 1);
        final cred = utf8.decode(base64Url.decode(base64Url.normalize(credB64)));
        final colonIdx = cred.indexOf(':');
        method = cred.substring(0, colonIdx);
        password = cred.substring(colonIdx + 1);
        final hostPort = hostPart.split(':');
        address = hostPort[0];
        port = int.tryParse(hostPort[1]) ?? 443;
      } else {
        final decoded = utf8.decode(base64Url.decode(base64Url.normalize(raw)));
        // method:password@host:port
        final atIdx = decoded.lastIndexOf('@');
        final cred = decoded.substring(0, atIdx);
        final hostPart = decoded.substring(atIdx + 1);
        final colonIdx = cred.indexOf(':');
        method = cred.substring(0, colonIdx);
        password = cred.substring(colonIdx + 1);
        final hostPort = hostPart.split(':');
        address = hostPort[0];
        port = int.tryParse(hostPort[1]) ?? 443;
      }

      return V2RayConfig(
        id: _uuid.v4(),
        name: name.isNotEmpty ? name : address,
        address: address,
        port: port,
        type: ConfigType.shadowsocks,
        rawLink: link,
        extra: {'method': method, 'password': password},
      );
    } catch (_) {
      return null;
    }
  }

  static String _decodeName(String raw) {
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }
}
