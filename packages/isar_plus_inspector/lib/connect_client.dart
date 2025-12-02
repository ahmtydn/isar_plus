import 'dart:async';
import 'dart:convert';

import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_inspector/connect_client.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:isar_plus/src/isar_connect_api.dart';

enum InspectorConnectionState {
  connected,
  disconnected,
  reconnecting,
}

class ConnectClient {
  ConnectClient._({
    required this.port,
    required this.secret,
    required VmService vmService,
    required String isolateId,
  })  : _vmService = vmService,
        _isolateId = isolateId;

  static const kNormalTimeout = Duration(seconds: 4);
  static const kLongTimeout = Duration(seconds: 10);
  static const kReconnectDelay = Duration(seconds: 2);
  static const kMaxReconnectAttempts = 10;
  static const kHealthCheckInterval = Duration(seconds: 3);

  final String port;
  final String secret;
  final collectionInfo = <String, ConnectCollectionInfoPayload>{};

  VmService _vmService;
  String _isolateId;
  InspectorConnectionState _connectionState =
      InspectorConnectionState.connected;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;

  final _instancesChangedController = StreamController<void>.broadcast();
  final _collectionInfoChangedController = StreamController<void>.broadcast();
  final _queryChangedController = StreamController<void>.broadcast();
  final _connectionStateController =
      StreamController<InspectorConnectionState>.broadcast();

  VmService get vmService => _vmService;
  String get isolateId => _isolateId;
  InspectorConnectionState get connectionState => _connectionState;

  Stream<void> get instancesChanged => _instancesChangedController.stream;
  Stream<void> get collectionInfoChanged =>
      _collectionInfoChangedController.stream;
  Stream<void> get queryChanged => _queryChangedController.stream;
  Stream<InspectorConnectionState> get connectionStateChanged =>
      _connectionStateController.stream;

  static Future<ConnectClient> connect(String port, String secret) async {
    final client = await _createClient(port, secret);
    client._initializeHealthCheck();
    return client;
  }

  static Future<ConnectClient> _createClient(String port, String secret) async {
    final wsUrl = Uri.parse('ws://127.0.0.1:$port/$secret=/ws');
    final channel = WebSocketChannel.connect(wsUrl);
    final streamController = StreamController<dynamic>.broadcast();

    channel.stream.listen(
      streamController.add,
      onError: streamController.addError,
      onDone: streamController.close,
    );

    try {
      final service = VmService(
        streamController.stream,
        channel.sink.add,
        disposeHandler: channel.sink.close,
      );

      final vm = await service.getVM().timeout(kNormalTimeout);
      final isolateId = vm.isolates!.firstWhere((e) => e.name == 'main').id!;
      await service.streamListen(EventStreams.kExtension);

      final client = ConnectClient._(
        port: port,
        secret: secret,
        vmService: service,
        isolateId: isolateId,
      );

      client._registerEventHandlers();
      return client;
    } catch (e) {
      await streamController.close();
      rethrow;
    }
  }

  void _registerEventHandlers() {
    _vmService.onExtensionEvent.listen(
      _processExtensionEvent,
      onError: (_) => _onConnectionLost(),
      onDone: _onConnectionLost,
    );
  }

  void _processExtensionEvent(Event event) {
    final data = event.extensionData?.data ?? {};
    final kind = event.extensionKind;

    if (kind == ConnectEvent.instancesChanged.event) {
      _instancesChangedController.add(null);
    } else if (kind == ConnectEvent.collectionInfoChanged.event) {
      final info = ConnectCollectionInfoPayload.fromJson(data);
      collectionInfo[info.collection] = info;
      _collectionInfoChangedController.add(null);
    } else if (kind == ConnectEvent.queryChanged.event) {
      _queryChangedController.add(null);
    }
  }

  void _initializeHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer =
        Timer.periodic(kHealthCheckInterval, (_) => _performHealthCheck());
  }

  Future<void> _performHealthCheck() async {
    if (_isDisposed ||
        _connectionState == InspectorConnectionState.reconnecting) {
      return;
    }

    try {
      await _vmService.getVM().timeout(kNormalTimeout);
    } on Object catch (_) {
      _onConnectionLost();
    }
  }

  void _onConnectionLost() {
    if (_isDisposed ||
        _connectionState == InspectorConnectionState.reconnecting) {
      return;
    }

    _updateConnectionState(InspectorConnectionState.disconnected);
    _scheduleReconnection();
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;

    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= kMaxReconnectAttempts) {
      _updateConnectionState(InspectorConnectionState.disconnected);
      return;
    }

    _updateConnectionState(InspectorConnectionState.reconnecting);
    _reconnectAttempts++;

    final delay = Duration(
      milliseconds: kReconnectDelay.inMilliseconds * _reconnectAttempts,
    );

    _reconnectTimer = Timer(delay, _executeReconnection);
  }

  Future<void> _executeReconnection() async {
    if (_isDisposed) return;

    try {
      final newClient = await _createClient(port, secret);
      _vmService = newClient._vmService;
      _isolateId = newClient._isolateId;
      collectionInfo.clear();

      _registerEventHandlers();
      _reconnectAttempts = 0;
      _updateConnectionState(InspectorConnectionState.connected);
      _initializeHealthCheck();
      _instancesChangedController.add(null);
    } on Object catch (_) {
      _scheduleReconnection();
    }
  }

  void _updateConnectionState(InspectorConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  bool _isStaleIsolateError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('sentinel') ||
        errorStr.contains('collected') ||
        errorStr.contains('isolate') ||
        errorStr.contains('not found');
  }

  Future<Map<String, dynamic>?> _invokeServiceMethod(
    ConnectAction action, {
    Duration? timeout = kNormalTimeout,
    dynamic param,
  }) async {
    try {
      var call = vmService.callServiceExtension(
        action.method,
        isolateId: isolateId,
        args: {if (param != null) 'args': jsonEncode(param)},
      );

      if (timeout != null) call = call.timeout(timeout);

      final response = await call;
      return response.json?['result'] as Map<String, dynamic>?;
    } catch (e) {
      if (_isStaleIsolateError(e)) _onConnectionLost();
      rethrow;
    }
  }

  Future<List<IsarSchema>> getSchemas(String instance) async {
    final json = await _invokeServiceMethod(
      ConnectAction.getSchemas,
      param: ConnectInstancePayload(instance),
    );
    return ConnectSchemasPayload.fromJson(json!).schemas;
  }

  Future<List<String>> listInstances() async {
    final json = await _invokeServiceMethod(ConnectAction.listInstances);
    return ConnectInstanceNamesPayload.fromJson(json!).instances;
  }

  Future<void> watchInstance(String instance) async {
    collectionInfo.clear();
    await _invokeServiceMethod(
      ConnectAction.watchInstance,
      param: ConnectInstancePayload(instance),
    );
  }

  Future<ConnectObjectsPayload> executeQuery(ConnectQueryPayload query) async {
    final json = await _invokeServiceMethod(
      ConnectAction.executeQuery,
      param: query,
      timeout: kLongTimeout,
    );
    return ConnectObjectsPayload.fromJson(json!);
  }

  Future<void> deleteQuery(ConnectQueryPayload query) async {
    await _invokeServiceMethod(
      ConnectAction.deleteQuery,
      param: query,
      timeout: kLongTimeout,
    );
  }

  Future<void> importJson(ConnectObjectsPayload objects) async {
    await _invokeServiceMethod(ConnectAction.importJson, param: objects);
  }

  Future<ConnectObjectsPayload> exportJson(ConnectQueryPayload query) async {
    final json = await _invokeServiceMethod(
      ConnectAction.exportJson,
      param: query,
      timeout: kLongTimeout,
    );
    return ConnectObjectsPayload.fromJson(json!);
  }

  Future<void> editProperty(ConnectEditPayload edit) async {
    await _invokeServiceMethod(
      ConnectAction.editProperty,
      param: edit,
      timeout: kLongTimeout,
    );
  }

  Future<void> disconnect() async {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    await _vmService.dispose();
    await Future.wait([
      _instancesChangedController.close(),
      _collectionInfoChangedController.close(),
      _queryChangedController.close(),
      _connectionStateController.close(),
    ]);
  }
}
