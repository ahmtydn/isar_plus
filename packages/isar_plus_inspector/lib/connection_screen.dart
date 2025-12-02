import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar_plus_inspector/connect_client.dart';
import 'package:isar_plus_inspector/connected_layout.dart';
import 'package:isar_plus_inspector/error_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({required this.port, required this.secret, super.key});

  final String port;
  final String secret;

  @override
  State<ConnectionScreen> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionScreen> {
  Future<ConnectClient>? clientFuture;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 15;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant ConnectionScreen oldWidget) {
    if (oldWidget.port != widget.port || oldWidget.secret != widget.secret) {
      _cancelRetry();
      _retryCount = 0;
      _connect();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _cancelRetry();
    super.dispose();
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _connect() {
    setState(() {
      clientFuture = ConnectClient.connect(widget.port, widget.secret);
    });
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;

    _cancelRetry();
    _retryCount++;

    final delay = Duration(
      milliseconds: _retryDelay.inMilliseconds * (_retryCount.clamp(1, 5)),
    );

    _retryTimer = Timer(delay, () {
      if (mounted) {
        _connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectClient>(
      future: clientFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _retryCount = 0; // Reset retry count on successful connection
          return _InspectorConnectionStateHandler(
            client: snapshot.data!,
            onDisconnected: () {
              // When client reports final disconnect, restart connection process
              _retryCount = 0;
              _connect();
            },
          );
        } else if (snapshot.hasError) {
          // Auto-retry on error
          if (_retryCount < _maxRetries) {
            _scheduleRetry();
            return _ConnectingOverlay(
              retryCount: _retryCount,
              maxRetries: _maxRetries,
            );
          }
          return ErrorScreen(
            onRetry: () {
              _retryCount = 0;
              _connect();
            },
          );
        } else {
          return const Loading();
        }
      },
    );
  }
}

class _InspectorConnectionStateHandler extends StatefulWidget {
  const _InspectorConnectionStateHandler({
    required this.client,
    required this.onDisconnected,
  });

  final ConnectClient client;
  final VoidCallback onDisconnected;

  @override
  State<_InspectorConnectionStateHandler> createState() =>
      _InspectorConnectionStateHandlerState();
}

class _InspectorConnectionStateHandlerState
    extends State<_InspectorConnectionStateHandler> {
  late StreamSubscription<InspectorConnectionState> _connectionSubscription;
  InspectorConnectionState _connectionState =
      InspectorConnectionState.connected;

  @override
  void initState() {
    super.initState();
    _connectionState = widget.client.connectionState;
    _connectionSubscription =
        widget.client.connectionStateChanged.listen((state) {
      if (mounted) {
        setState(() => _connectionState = state);

        // If max retries exceeded in client, trigger parent reconnection
        if (state == InspectorConnectionState.disconnected) {
          widget.onDisconnected();
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_connectionSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _InstancesLoader(client: widget.client),
        if (_connectionState == InspectorConnectionState.reconnecting)
          const _ReconnectingOverlay(),
      ],
    );
  }
}

class _ReconnectingOverlay extends StatelessWidget {
  const _ReconnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Reconnecting...',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Hot reload/restart detected',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectingOverlay extends StatelessWidget {
  const _ConnectingOverlay({
    required this.retryCount,
    required this.maxRetries,
  });

  final int retryCount;
  final int maxRetries;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Connecting...',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Attempt $retryCount of $maxRetries',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Waiting for application to start...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstancesLoader extends StatefulWidget {
  const _InstancesLoader({required this.client});

  final ConnectClient client;

  @override
  State<_InstancesLoader> createState() => _InstancesLoaderState();
}

class _InstancesLoaderState extends State<_InstancesLoader> {
  Future<List<String>>? instancesFuture;
  late StreamSubscription<void> _instancesSubscription;

  @override
  void initState() {
    super.initState();
    _loadInstances();
    _instancesSubscription = widget.client.instancesChanged.listen((event) {
      _loadInstances();
    });
  }

  void _loadInstances() {
    if (widget.client.connectionState == InspectorConnectionState.connected) {
      setState(() {
        instancesFuture = widget.client.listInstances();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _InstancesLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInstances();
  }

  @override
  void dispose() {
    unawaited(_instancesSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (instancesFuture == null) {
      return const Loading();
    }

    return FutureBuilder<List<String>>(
      future: instancesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ConnectedLayout(
            client: widget.client,
            instances: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          // Error will trigger reconnection via _call method
          // Show loading while reconnecting
          return const Loading();
        } else {
          return const Loading();
        }
      },
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
