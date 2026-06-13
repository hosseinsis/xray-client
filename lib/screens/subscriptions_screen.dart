import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/v2ray_config.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: provider.subscriptions.isEmpty
          ? _buildEmpty(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.subscriptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final sub = provider.subscriptions[i];
                return _SubCard(sub: sub);
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

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('سابسکریپشنی وجود ندارد',
                style: TextStyle(color: Color(0xFF8888AA), fontSize: 16)),
            const SizedBox(height: 8),
            const Text('لینک سابسکریپشن اضافه کنید',
                style: TextStyle(color: Color(0xFF555577), fontSize: 13)),
          ],
        ),
      );

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddSubSheet(),
    );
  }
}

class _SubCard extends StatelessWidget {
  final Subscription sub;
  const _SubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isLoading = provider.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A45)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.rss_feed,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(sub.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              sub.url,
              style: const TextStyle(fontSize: 11, color: Color(0xFF555577)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub.lastUpdated != null) ...[
              const SizedBox(height: 2),
              Text(
                '${sub.configCount} کانفیگ · آخرین آپدیت: ${_formatDate(sub.lastUpdated!)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8888AA)),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
              onPressed: isLoading
                  ? null
                  : () => context.read<AppProvider>().updateSubscription(sub.id),
              tooltip: 'آپدیت',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Color(0xFFFF5C7A)),
              onPressed: () => _confirmDelete(context, sub),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Subscription sub) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('حذف سابسکریپشن'),
        content: Text('سابسکریپشن "${sub.name}" و کانفیگ‌های آن حذف شوند؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeSubscription(sub.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5C7A)),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _AddSubSheet extends StatefulWidget {
  const _AddSubSheet();

  @override
  State<_AddSubSheet> createState() => _AddSubSheetState();
}

class _AddSubSheetState extends State<_AddSubSheet> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

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
          const Text('افزودن سابسکریپشن',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'نام',
              hintText: 'مثلاً: سرور اصلی',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'لینک سابسکریپشن',
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('ذخیره و آپدیت'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => _error = 'همه فیلدها را پر کنید');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _error = 'URL معتبر وارد کنید');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppProvider>().addSubscription(name, url);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'خطا: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }
}
