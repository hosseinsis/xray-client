import 'package:flutter/material.dart';
import '../providers/app_provider.dart';

class ConnectButton extends StatefulWidget {
  final ConnectionState state;
  final VoidCallback onTap;

  const ConnectButton({super.key, required this.state, required this.onTap});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.state == ConnectionState.connected;
    final connecting = widget.state == ConnectionState.connecting;

    final Color primary =
        connected ? const Color(0xFF00D4AA) : Theme.of(context).colorScheme.primary;
    final String label = connected
        ? 'قطع اتصال'
        : connecting
            ? 'در حال اتصال...'
            : 'اتصال';

    return GestureDetector(
      onTap: connecting ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: (connected || connecting) ? _pulse.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primary.withOpacity(0.3),
                primary.withOpacity(0.0),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.15),
                border: Border.all(color: primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: connected ? 30 : 16,
                    spreadRadius: connected ? 4 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (connecting)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primary,
                      ),
                    )
                  else
                    Icon(
                      connected ? Icons.power_settings_new : Icons.power_settings_new,
                      size: 36,
                      color: primary,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
