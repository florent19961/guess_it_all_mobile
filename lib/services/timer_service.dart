import 'dart:async';

class TimerService {
  Timer? _timer;
  DateTime? _endTime;
  final void Function(int secondsRemaining) onTick;
  final VoidCallback onTimeUp;

  TimerService({
    required this.onTick,
    required this.onTimeUp,
  });

  void start(int durationSeconds) {
    _endTime = DateTime.now().add(Duration(seconds: durationSeconds));
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _tick(Timer timer) {
    if (_endTime == null) return;

    final now = DateTime.now();
    final remaining = _endTime!.difference(now).inMilliseconds;
    final remainingSeconds = (remaining / 1000).ceil();

    if (remaining <= 0) {
      stop();
      onTimeUp();
    } else {
      onTick(remainingSeconds);
    }
  }

  int pause() {
    _timer?.cancel();
    if (_endTime == null) return 0;
    final remaining = _endTime!.difference(DateTime.now()).inMilliseconds;
    return (remaining / 1000).ceil().clamp(0, 999);
  }

  void resume(int secondsRemaining) {
    _endTime = DateTime.now().add(Duration(seconds: secondsRemaining));
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void subtractPenalty(int penaltySeconds) {
    if (_endTime == null) return;
    _endTime = _endTime!.subtract(Duration(seconds: penaltySeconds));
    final remaining = _endTime!.difference(DateTime.now()).inMilliseconds;
    if (remaining <= 0) {
      stop();
      onTimeUp();
    }
  }

  int get currentRemaining {
    if (_endTime == null) return 0;
    final remaining = _endTime!.difference(DateTime.now()).inMilliseconds;
    return (remaining / 1000).ceil().clamp(0, 999);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
  }

  void dispose() {
    stop();
  }
}

typedef VoidCallback = void Function();
