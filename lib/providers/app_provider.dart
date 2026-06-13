import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:uuid/uuid.dart';
import '../models/v2ray_config.dart';
import '../services/config_parser.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

const _uuid = Uuid();

enum ConnectionState { disconnected, connecting, connected }

class AppProvider extends ChangeNotifier {
  List<V2RayConfig> configs = [];
  List<Subscription> subscriptions = [];
  String? selectedConfigId;
  ConnectionState connectionState = ConnectionState.disconnected;
  String? errorMessage;
  bool isLoading = false;

  late FlutterV2ray _flutterV2ray;

  V2RayConfig? get selectedConfig =>
      configs.where((c) => c.id == selectedConfigId).firstOrNull;

  bool get isConnected => connectionState == ConnectionState.connected;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        if (status.state == 'CONNECTED') {
          connectionState = ConnectionState.connected;
        } else if (status.state == 'DISCONNECTED') {
          connectionState = ConnectionState.disconnected;
        } else if (status.state == 'CONNECTING') {
          connectionState = ConnectionState.connecting;
        }
        notifyListeners();
      },
    );
    await _flutterV2ray.initializeV2Ray();
    await _loadData();
  }

  Future<void> _loadData() async {
    configs = await StorageService.loadConfigs();
    subscriptions = await StorageService.loadSubscriptions();
    selectedConfigId = await StorageService.loadSelectedId();
    notifyListeners();
  }

  // ── Connection ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    final config = selectedConfig;
    if (config == null) return;

    errorMessage = null;
    connectionState = ConnectionState.connecting;
    notifyListeners();

    try {
      final hasPermission = await _flutterV2ray.requestPermission();
      if (!hasPermission) {
        errorMessage = 'دسترسی VPN داده نشد';
        connectionState = ConnectionState.disconnected;
        notifyListeners();
        return;
      }

      await _flutterV2ray.startV2Ray(
        remark: config.name,
        config: _buildXrayConfig(config),
        blockedApps: [],
        bypassSubnets: [],
        proxyOnly: false,
      );
    } catch (e) {
      errorMessage = 'خطا در اتصال: $e';
      connectionState = ConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _flutterV2ray.stopV2Ray();
    connectionState = ConnectionState.disconnected;
    notifyListeners();
  }

  // ── Config management ──────────────────────────────────────────────────────

  Future<bool> addConfigFromLink(String link) async {
    final config = ConfigParser.parse(link.trim());
    if (config == null) return false;

    configs.add(config);
    selectedConfigId ??= config.id;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<int> addConfigsFromText(String text) async {
    final parsed = ConfigParser.parseMultiple(text);
    if (parsed.isEmpty) return 0;
    configs.addAll(parsed);
    selectedConfigId ??= parsed.first.id;
    await _persist();
    notifyListeners();
    return parsed.length;
  }

  Future<void> removeConfig(String id) async {
    if (selectedConfigId == id) {
      await disconnect();
      selectedConfigId = configs.isNotEmpty ? configs.first.id : null;
    }
    configs.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  void selectConfig(String id) {
    if (isConnected) disconnect();
    selectedConfigId = id;
    StorageService.saveSelectedId(id);
    notifyListeners();
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  Future<void> addSubscription(String name, String url) async {
    final sub = Subscription(id: _uuid.v4(), name: name, url: url);
    subscriptions.add(sub);
    await StorageService.saveSubscriptions(subscriptions);
    notifyListeners();
    await updateSubscription(sub.id);
  }

  Future<void> updateSubscription(String id) async {
    final idx = subscriptions.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    isLoading = true;
    notifyListeners();

    try {
      final sub = subscriptions[idx];
      final fetched = await SubscriptionService.fetchSubscription(sub.url);

      // Remove old configs from this subscription, add new
      configs.removeWhere((c) => c.extra['subId'] == id);
      final tagged = fetched
          .map((c) => V2RayConfig(
                id: c.id,
                name: c.name,
                address: c.address,
                port: c.port,
                type: c.type,
                rawLink: c.rawLink,
                extra: {...c.extra, 'subId': id},
              ))
          .toList();
      configs.addAll(tagged);
      selectedConfigId ??= tagged.isNotEmpty ? tagged.first.id : null;

      subscriptions[idx] = sub.copyWith(
        lastUpdated: DateTime.now(),
        configCount: tagged.length,
      );

      await _persist();
    } catch (e) {
      errorMessage = 'خطا در آپدیت سابسکریپشن: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSubscription(String id) async {
    configs.removeWhere((c) => c.extra['subId'] == id);
    subscriptions.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.saveConfigs(configs);
    await StorageService.saveSubscriptions(subscriptions);
    await StorageService.saveSelectedId(selectedConfigId);
  }

  // ── Xray JSON config builder ───────────────────────────────────────────────

  String _buildXrayConfig(V2RayConfig config) {
    Map<String, dynamic> outbound;

    switch (config.type) {
      case ConfigType.vmess:
        outbound = _vmessOutbound(config);
        break;
      case ConfigType.vless:
        outbound = _vlessOutbound(config);
        break;
      case ConfigType.trojan:
        outbound = _trojanOutbound(config);
        break;
      case ConfigType.shadowsocks:
        outbound = _ssOutbound(config);
        break;
      default:
        throw Exception('Unsupported config type');
    }

    final xray = {
      'log': {'loglevel': 'warning'},
      'inbounds': [
        {
          'tag': 'socks',
          'protocol': 'socks',
          'listen': '127.0.0.1',
          'port': 10808,
          'settings': {'auth': 'noauth', 'udp': true},
        },
        {
          'tag': 'http',
          'protocol': 'http',
          'listen': '127.0.0.1',
          'port': 10809,
        }
      ],
      'outbounds': [
        outbound,
        {'tag': 'direct', 'protocol': 'freedom'},
        {'tag': 'block', 'protocol': 'blackhole'},
      ],
      'routing': {
        'domainStrategy': 'IPIfNonMatch',
        'rules': [
          {
            'type': 'field',
            'outboundTag': 'direct',
            'ip': ['geoip:private'],
          }
        ],
      },
    };
    return xray.toString().replaceAll("'", '"'); // Ensure JSON-compatible quotes
    // NOTE: In production use jsonEncode(xray)
  }

  Map<String, dynamic> _vmessOutbound(V2RayConfig c) => {
        'tag': 'proxy',
        'protocol': 'vmess',
        'settings': {
          'vnext': [
            {
              'address': c.address,
              'port': c.port,
              'users': [
                {
                  'id': c.extra['id'],
                  'alterId': int.tryParse(c.extra['alterId']?.toString() ?? '0') ?? 0,
                  'security': c.extra['scy'] ?? 'auto',
                }
              ],
            }
          ]
        },
        'streamSettings': _streamSettings(c),
      };

  Map<String, dynamic> _vlessOutbound(V2RayConfig c) => {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': c.address,
              'port': c.port,
              'users': [
                {
                  'id': c.extra['uuid'],
                  'encryption': c.extra['encryption'] ?? 'none',
                  'flow': c.extra['flow'] ?? '',
                }
              ],
            }
          ]
        },
        'streamSettings': _streamSettings(c),
      };

  Map<String, dynamic> _trojanOutbound(V2RayConfig c) => {
        'tag': 'proxy',
        'protocol': 'trojan',
        'settings': {
          'servers': [
            {
              'address': c.address,
              'port': c.port,
              'password': c.extra['password'],
            }
          ]
        },
        'streamSettings': _streamSettings(c),
      };

  Map<String, dynamic> _ssOutbound(V2RayConfig c) => {
        'tag': 'proxy',
        'protocol': 'shadowsocks',
        'settings': {
          'servers': [
            {
              'address': c.address,
              'port': c.port,
              'method': c.extra['method'],
              'password': c.extra['password'],
            }
          ]
        },
      };

  Map<String, dynamic> _streamSettings(V2RayConfig c) {
    final network = c.extra['type'] ?? c.extra['network'] ?? 'tcp';
    final security = c.extra['security'] ?? c.extra['tls'] ?? 'none';

    Map<String, dynamic> settings = {'network': network};

    // TLS / Reality
    if (security == 'tls') {
      settings['security'] = 'tls';
      settings['tlsSettings'] = {
        'serverName': c.extra['sni'] ?? c.extra['host'] ?? c.address,
        'fingerprint': c.extra['fp'] ?? '',
        'alpn': (c.extra['alpn'] as String?)?.split(',') ?? [],
      };
    } else if (security == 'reality') {
      settings['security'] = 'reality';
      settings['realitySettings'] = {
        'serverName': c.extra['sni'] ?? c.address,
        'fingerprint': c.extra['fp'] ?? 'chrome',
        'publicKey': c.extra['pbk'] ?? '',
        'shortId': c.extra['sid'] ?? '',
        'spiderX': c.extra['spx'] ?? '',
      };
    } else {
      settings['security'] = 'none';
    }

    // WebSocket
    if (network == 'ws') {
      settings['wsSettings'] = {
        'path': c.extra['path'] ?? '/',
        'headers': {'Host': c.extra['host'] ?? c.address},
      };
    }
    // gRPC
    else if (network == 'grpc') {
      settings['grpcSettings'] = {
        'serviceName': c.extra['path'] ?? '',
        'multiMode': false,
      };
    }
    // HTTP/2
    else if (network == 'h2') {
      settings['httpSettings'] = {
        'path': c.extra['path'] ?? '/',
        'host': [c.extra['host'] ?? c.address],
      };
    }
    // XHTTP / SplitHTTP
    else if (network == 'xhttp' || network == 'splithttp') {
      settings['xhttpSettings'] = {
        'path': c.extra['path'] ?? '/',
        'host': c.extra['host'] ?? c.address,
        'mode': 'stream-one',
      };
    }

    return settings;
  }
}
