import 'dart:convert';

enum ConfigType { vmess, vless, trojan, shadowsocks, unknown }

class V2RayConfig {
  final String id;
  final String name;
  final String address;
  final int port;
  final ConfigType type;
  final String rawLink;
  final Map<String, dynamic> extra;
  final DateTime addedAt;
  int latency; // ms, -1 = untested

  V2RayConfig({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.type,
    required this.rawLink,
    this.extra = const {},
    DateTime? addedAt,
    this.latency = -1,
  }) : addedAt = addedAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case ConfigType.vmess:
        return 'VMess';
      case ConfigType.vless:
        return 'VLESS';
      case ConfigType.trojan:
        return 'Trojan';
      case ConfigType.shadowsocks:
        return 'Shadowsocks';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'port': port,
        'type': type.name,
        'rawLink': rawLink,
        'extra': extra,
        'addedAt': addedAt.toIso8601String(),
        'latency': latency,
      };

  factory V2RayConfig.fromJson(Map<String, dynamic> json) => V2RayConfig(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        port: json['port'],
        type: ConfigType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConfigType.unknown,
        ),
        rawLink: json['rawLink'],
        extra: Map<String, dynamic>.from(json['extra'] ?? {}),
        addedAt: DateTime.parse(json['addedAt']),
        latency: json['latency'] ?? -1,
      );
}

class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime? lastUpdated;
  final int configCount;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.lastUpdated,
    this.configCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'configCount': configCount,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : null,
        configCount: json['configCount'] ?? 0,
      );

  Subscription copyWith({
    String? name,
    String? url,
    DateTime? lastUpdated,
    int? configCount,
  }) =>
      Subscription(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        configCount: configCount ?? this.configCount,
      );
}
