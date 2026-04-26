import 'package:flutter/foundation.dart';

class AmountInputController extends ChangeNotifier {
  String _raw = '';

  String get raw => _raw;
  int get value => _raw.isEmpty ? 0 : int.parse(_raw);
  bool get hasValue => _raw.isNotEmpty && value > 0;

  String get formatted {
    if (_raw.isEmpty) return '0';
    final n = int.parse(_raw);
    // format kiểu 50.000
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  void press(String key) {
    switch (key) {
      case '⌫':
        if (_raw.isNotEmpty) {
          _raw = _raw.substring(0, _raw.length - 1);
        }
      case '00':
        if (_raw.isNotEmpty && _raw.length <= 8) {
          _raw += '00';
        }
      default:
        if (_raw.length >= 10) return;
        if (_raw.isEmpty && key == '0') return; // no leading zero
        _raw += key;
    }
    notifyListeners();
  }

  void prefill(String rawValue) {
    _raw = rawValue;
    notifyListeners();
  }

  void reset() {
    _raw = '';
    notifyListeners();
  }
}