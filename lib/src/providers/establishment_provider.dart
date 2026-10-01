import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class EstablishmentProvider extends ChangeNotifier {
  String _name = '';
  String _ruc = '';
  String _code = '';
  bool _isLoading = false;

  String get name => _name;
  String get ruc => _ruc;
  String get code => _code;
  bool get isLoading => _isLoading;
  bool get isComplete => _name.isNotEmpty && _ruc.isNotEmpty && _code.isNotEmpty;

  EstablishmentProvider() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final info = await getEstablishmentInfo();
      _name = info['name'] ?? '';
      _ruc = info['ruc'] ?? '';
      _code = info['code'] ?? '';
    } catch (e) {
      debugPrint('Error loading establishment info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String name,
    required String ruc,
    required String code,
  }) async {
    try {
      await setEstablishmentInfo(name: name, ruc: ruc, code: code);
      _name = name;
      _ruc = ruc;
      _code = code;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving establishment info: $e');
      rethrow;
    }
  }
}
