// Model untuk satu item di dalam daftar pesanan
class ItemPesanan {
  final String menuId;
  final String namaMenu;
  final int harga;
  int jumlah;

  ItemPesanan({
    required this.menuId,
    required this.namaMenu,
    required this.harga,
    required this.jumlah,
  });

  // Dari Map (Firestore) ke Object
  factory ItemPesanan.fromMap(Map<String, dynamic> map) {
    return ItemPesanan(
      menuId: map['menuId'],
      namaMenu: map['namaMenu'],
      harga: map['harga'],
      jumlah: map['jumlah'],
    );
  }

  // Dari Object ke Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'namaMenu': namaMenu,
      'harga': harga,
      'jumlah': jumlah,
    };
  }
}