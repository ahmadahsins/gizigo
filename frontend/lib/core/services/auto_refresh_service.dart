import 'dart:async';

import 'package:flutter/widgets.dart';

class AutoRefreshService with WidgetsBindingObserver {
  AutoRefreshService._();

  static final AutoRefreshService instance = AutoRefreshService._();
  static const Duration refreshInterval = Duration(seconds: 20);

  final StreamController<int> _ticks = StreamController<int>.broadcast();
  Timer? _timer;
  int _tick = 0;
  bool _isStarted = false;
  bool _isActive = true;

  Stream<int> get ticks => _ticks.stream;

  void start() {
    if (_isStarted) return;

    _isStarted = true;
    WidgetsBinding.instance.addObserver(this);
    _isActive =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    _scheduleTimer();
    refreshNow();
  }

  void stop() {
    if (!_isStarted) return;

    _isStarted = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  void refreshNow() {
    if (!_isStarted || !_isActive || _ticks.isClosed) return;

    _ticks.add(++_tick);
  }

  void _scheduleTimer() {
    _timer?.cancel();
    if (!_isActive) return;

    _timer = Timer.periodic(refreshInterval, (_) => refreshNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isActive = true;
      _scheduleTimer();
      refreshNow();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isActive = false;
      _timer?.cancel();
      _timer = null;
    }
  }
}

mixin AutoRefreshStateMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<int>? _autoRefreshSubscription;
  bool _isAutoRefreshRunning = false;

  @protected
  bool get canAutoRefresh => ModalRoute.of(context)?.isCurrent ?? true;

  @protected
  FutureOr<void> onAutoRefresh();

  @override
  void initState() {
    super.initState();
    _autoRefreshSubscription = AutoRefreshService.instance.ticks.listen((_) {
      _runAutoRefresh();
    });
  }

  Future<void> _runAutoRefresh() async {
    if (!mounted || _isAutoRefreshRunning || !canAutoRefresh) return;

    _isAutoRefreshRunning = true;
    try {
      await onAutoRefresh();
    } finally {
      _isAutoRefreshRunning = false;
    }
  }

  @override
  void dispose() {
    _autoRefreshSubscription?.cancel();
    super.dispose();
  }
}
