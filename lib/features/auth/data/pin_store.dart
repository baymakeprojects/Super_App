import 'package:super_app/core/storage/key_value_store.dart';

/// PIN cadangan 6 angka untuk membuka app saat sidik jari tidak bisa
/// dipakai (H06). Disimpan terenkripsi di HP, tidak pernah ke server.
/// PIN diatur di H05 (W4-04); sebelum itu belum ada PIN.
class PinStore {
  const PinStore(this._store);

  static const int length = 6;

  final KeyValueStore _store;

  Future<bool> hasPin() async => await _store.read(StoreKeys.pin) != null;

  Future<bool> verify(String pin) async =>
      pin.length == length && await _store.read(StoreKeys.pin) == pin;

  Future<void> setPin(String pin) {
    if (pin.length != length || int.tryParse(pin) == null) {
      throw ArgumentError.value(pin, 'pin', 'Harus $length angka');
    }
    return _store.write(StoreKeys.pin, pin);
  }
}
