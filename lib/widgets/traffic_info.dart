import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

class TrafficInfo extends StatelessWidget {
  const TrafficInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<V2RayStatus>(
      stream: FlutterV2ray.v2RayStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final upload = _formatBytes(status?.uploadSpeed ?? 0);
        final download = _formatBytes(status?.downloadSpeed ?? 0);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrafficItem(
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFF6C63FF),
                label: 'آپلود',
                value: upload,
              ),
              Container(
                  height: 40, width: 1, color: const Color(0xFF2A2A45)),
              _TrafficItem(
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF00D4AA),
                label: 'دانلود',
                value: download,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB/s';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB/s';
  }
}

class _TrafficItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _TrafficItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF8888AA))),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ],
    );
  }
}
