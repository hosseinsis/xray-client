import 'package:flutter/material.dart';
import '../models/v2ray_config.dart';

class ConfigCard extends StatelessWidget {
  final V2RayConfig config;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ConfigCard({
    super.key,
    required this.config,
    required this.isSelected,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary : const Color(0xFF2A2A45),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Protocol badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor(config.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  config.typeLabel,
                  style: TextStyle(
                    color: _typeColor(config.type),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${config.address}:${config.port}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8888AA),
                      ),
                    ),
                  ],
                ),
              ),
              // Latency
              if (config.latency > 0)
                _LatencyChip(latency: config.latency),
              // Selected indicator
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              // Delete
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF555577)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(ConfigType type) {
    switch (type) {
      case ConfigType.vmess:
        return const Color(0xFF6C63FF);
      case ConfigType.vless:
        return const Color(0xFF00D4AA);
      case ConfigType.trojan:
        return const Color(0xFFFF9500);
      case ConfigType.shadowsocks:
        return const Color(0xFFFF5C7A);
      default:
        return const Color(0xFF8888AA);
    }
  }
}

class _LatencyChip extends StatelessWidget {
  final int latency;
  const _LatencyChip({required this.latency});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (latency < 150) {
      color = const Color(0xFF00D4AA);
    } else if (latency < 400) {
      color = Colors.orange;
    } else {
      color = const Color(0xFFFF5C7A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${latency}ms',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
