import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'configs_screen.dart';
import 'subscriptions_screen.dart';
import '../widgets/connect_button.dart';
import '../widgets/config_card.dart';
import '../widgets/traffic_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('V2Ray Client'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _MainTab(),
          ConfigsScreen(),
          SubscriptionsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns_outlined),
            activeIcon: Icon(Icons.dns),
            label: 'کانفیگ‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            activeIcon: Icon(Icons.subscriptions),
            label: 'سابسکریپشن',
          ),
        ],
      ),
    );
  }
}

class _MainTab extends StatelessWidget {
  const _MainTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Status card
          _StatusCard(provider: provider),
          const SizedBox(height: 24),

          // Connect button
          ConnectButton(
            state: provider.connectionState,
            onTap: () {
              if (provider.isConnected) {
                provider.disconnect();
              } else {
                provider.connect();
              }
            },
          ),
          const SizedBox(height: 24),

          // Error message
          if (provider.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(),

          // Traffic info when connected
          if (provider.isConnected) ...[
            const SizedBox(height: 16),
            const TrafficInfo(),
          ],

          const SizedBox(height: 24),

          // Selected config
          if (provider.selectedConfig != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'کانفیگ انتخابی',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF8888AA),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ConfigCard(
              config: provider.selectedConfig!,
              isSelected: true,
              onTap: null,
            ),
          ] else
            _EmptyConfigHint(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AppProvider provider;
  const _StatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final connected = provider.isConnected;
    final connecting = provider.connectionState == ConnectionState.connecting;

    Color statusColor;
    String statusText;
    if (connected) {
      statusColor = const Color(0xFF00D4AA);
      statusText = 'متصل';
    } else if (connecting) {
      statusColor = Colors.orange;
      statusText = 'در حال اتصال...';
    } else {
      statusColor = const Color(0xFF555577);
      statusText = 'قطع';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'وضعیت: $statusText',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConfigHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A45),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 40,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'کانفیگی اضافه نشده',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8888AA),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'از تب کانفیگ‌ها لینک یا سابسکریپشن اضافه کنید',
            style: TextStyle(fontSize: 13, color: Color(0xFF555577)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
