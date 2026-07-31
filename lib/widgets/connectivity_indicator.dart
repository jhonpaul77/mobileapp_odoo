import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pintarx/providers/connectivity_provider.dart';

/// ConnectivityIndicator - WiFi status indicator for AppBar
///
/// Shows WiFi icon in green when online, red when offline
class ConnectivityIndicator extends StatelessWidget {
  final double size;
  final EdgeInsets padding;

  const ConnectivityIndicator({
    super.key,
    this.size = 24,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        final isOnline = connectivityProvider.isOnline;
        
        return Padding(
          padding: padding,
          child: Tooltip(
            message: isOnline ? 'Online' : 'Offline',
            child: Icon(
              Icons.wifi_rounded,
              size: size,
              color: isOnline ? Colors.green : Colors.red,
              semanticLabel: isOnline ? 'Online' : 'Offline',
            ),
          ),
        );
      },
    );
  }
}
