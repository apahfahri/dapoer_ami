// lib/models/bahan_menu_model.dart

class BahanMenu {
  final String bahanBakuId; // Merujuk ke ID dari collection 'bahan_baku'
  final String namaBahan;    // Disimpan agar tidak perlu query lagi untuk nama
  final double kuantitasPakai;
  final String satuanPakai;

  BahanMenu({
    required this.bahanBakuId,
    required this.namaBahan,
    required this.kuantitasPakai,
    required this.satuanPakai,
  });

  factory BahanMenu.fromMap(Map<String, dynamic> map) {
    return BahanMenu(
      bahanBakuId: map['bahanBakuId'] ?? '',
      namaBahan: map['namaBahan'] ?? '',
      kuantitasPakai: (map['kuantitasPakai'] as num).toDouble(),
      satuanPakai: map['satuanPakai'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bahanBakuId': bahanBakuId,
      'namaBahan': namaBahan,
      'kuantitasPakai': kuantitasPakai,
      'satuanPakai': satuanPakai,
    };
  }
}