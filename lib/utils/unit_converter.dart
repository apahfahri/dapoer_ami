// lib/utils/unit_converter.dart

class UnitConverter {
  // Peta faktor konversi ke unit dasar (gram untuk massa, ml untuk volume)
  static const Map<String, double> _factors = {
    // Massa (Dasar: gram)
    'g': 1.0,
    'gram': 1.0,
    'gr': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'ons': 100.0,

    // Volume (Dasar: ml)
    'ml': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'sdm': 15.0, // sendok makan ~ 15 ml
    'sdt': 5.0,  // sendok teh ~ 5 ml

    // Satuan (Dasar: unit itu sendiri)
    'butir': 1.0,
    'buah': 1.0,
    'siung': 1.0,
    'ikat': 1.0,
    'pcs': 1.0,
  };

  // Peta untuk mengelompokkan jenis satuan
  static const Map<String, String> _unitTypes = {
    'g': 'massa', 'gram': 'massa', 'gr': 'massa', 'kg': 'massa', 'kilogram': 'massa', 'ons': 'massa',
    'ml': 'volume', 'l': 'volume', 'liter': 'volume', 'sdm': 'volume', 'sdt': 'volume',
    'butir': 'satuan', 'buah': 'satuan', 'siung': 'satuan', 'ikat': 'satuan', 'pcs': 'satuan',
  };

  static String? _getUnitType(String unit) {
    return _unitTypes[unit.toLowerCase()];
  }

  /// Mengonversi nilai dari satu satuan ke satuan lain.
  /// Contoh: convert(1, 'kg', 'g') akan mengembalikan 1000.
  /// Mengembalikan 0 jika konversi tidak memungkinkan (misal: kg ke liter).
  static double convert(double value, String fromUnit, String toUnit) {
    fromUnit = fromUnit.toLowerCase();
    toUnit = toUnit.toLowerCase();

    // Periksa apakah kedua unit ada di dalam daftar faktor
    if (!_factors.containsKey(fromUnit) || !_factors.containsKey(toUnit)) {
      print("Error: Satuan tidak dikenal '$fromUnit' or '$toUnit'");
      return 0;
    }
    
    // Periksa apakah kedua unit memiliki tipe yang sama (massa ke massa, volume ke volume)
    if (_getUnitType(fromUnit) != _getUnitType(toUnit)) {
       print("Error: Tidak bisa mengonversi antara tipe satuan yang berbeda ('$fromUnit' ke '$toUnit')");
       return 0;
    }

    // Ambil faktor konversi ke unit dasar
    double fromFactor = _factors[fromUnit]!;
    double toFactor = _factors[toUnit]!;

    // Konversi nilai ke unit dasar, lalu konversi ke unit tujuan
    double baseValue = value * fromFactor;
    return baseValue / toFactor;
  }
}