import 'dart:async';

class DecayableField<T> {
  final Duration timeout;
  T? _value;
  Timer? _timer;
  final void Function(T? newValue) _onChanged;

  DecayableField({
    this.timeout = const Duration(milliseconds: 1500),
    required this._onChanged,
  });

  T? get value => _value;

  void update(T? newValue) {
    _value = newValue;
    _timer?.cancel();
    if (newValue != null && timeout > Duration.zero) {
      _timer = Timer(timeout, () {
        _value = null;
        _onChanged(null);
      });
    } else {
      _timer = null;
    }
    _onChanged(newValue);
  }

  void sync(T? newValue) {
    _value = newValue;
    _timer?.cancel();
    if (newValue != null && timeout > Duration.zero) {
      _timer = Timer(timeout, () {
        _value = null;
        _onChanged(null);
      });
    } else {
      _timer = null;
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
