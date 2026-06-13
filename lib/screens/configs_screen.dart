import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/v2ray_config.dart';
import '../widgets/config_card.dart';

class ConfigsScreen extends StatelessWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: provider.configs.isEmpty
          ? _buildEmpty(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.configs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final config = provider.configs[i];
                return ConfigCard(
                  config: config,
                  isSelected: config.id == provider.selectedConfigId,
                  onTap: () => provider.selectConfig(config.id),
                  onDelete: () => _confirmDelete(context, provider, config),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('افزودن'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dns_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('هیچ کانفیگی وجود ندارد',
              style: TextStyle(color: Color(0xFF8888AA), fontSize: 16)),
          const SizedBox(height: 8),
          const Text('دکمه + را بزنید تا کانفیگ اضافه کنید',
              style: TextStyle(color: Color(0xFF555577), fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, V2RayConfig config) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('حذف کانفیگ'),
        content: Text('کانفیگ "${config.name}" حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              provider.removeConfig(config.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddConfigSheet(),
    );
  }
}

class _AddConfigSheet extends StatefulWidget {
  const _AddConfigSheet();

  @override
  State<_AddConfigSheet> createState() => _AddConfigSheetState();
}

class _AddConfigSheetState extends State<_AddConfigSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _linkController = TextEditingController();
  final _bulkController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkController.dispose();
    _bulkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333355),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'افزودن کانفیگ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: const Color(0xFF8888AA),
            tabs: const [
              Tab(text: 'لینک تکی'),
              Tab(text: 'چند لینک / متن'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Single link
                Column(
                  children: [
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'vmess:// یا vless:// یا trojan:// یا ss://',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste),
                          tooltip: 'جای‌گذاری',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _linkController.text = data!.text!;
                            }
                          },
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                // Bulk
                TextField(
                  controller: _bulkController,
                  decoration: const InputDecoration(
                    hintText: 'چند لینک را هر کدام در یک خط قرار دهید...',
                  ),
                  maxLines: 6,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('افزودن'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });

    bool success = false;
    if (_tabController.index == 0) {
      final link = _linkController.text.trim();
      if (link.isEmpty) {
        setState(() {
          _error = 'لینک خالی است';
          _loading = false;
        });
        return;
      }
      success = await provider.addConfigFromLink(link);
      if (!success) _error = 'لینک معتبر نیست';
    } else {
      final text = _bulkController.text.trim();
      if (text.isEmpty) {
        setState(() {
          _error = 'متن خالی است';
          _loading = false;
        });
        return;
      }
      final count = await provider.addConfigsFromText(text);
      if (count == 0) {
        _error = 'هیچ لینک معتبری یافت نشد';
      } else {
        success = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count کانفیگ اضافه شد')),
          );
        }
      }
    }

    setState(() => _loading = false);
    if (success && mounted) Navigator.pop(context);
  }
}
