// lib/models/menu_model.dart

// ... import lainnya
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bahan_menu_model.dart';

class Menu {
  final String id;
  final String namaMenu;
  final int harga; // Ini adalah harga jual akhir
  final String deskripsi;
  final List<BahanMenu> bahan;
  final double hpp; // <-- FIELD BARU: Harga Pokok Penjualan
  final double markup; // <-- FIELD BARU: Persentase keuntungan

  Menu({
    required this.id,
    required this.namaMenu,
    required this.harga,
    required this.deskripsi,
    required this.bahan,
    required this.hpp,
    required this.markup,
  });

  factory Menu.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    // ... (logika konversi bahan tidak berubah)
    List<BahanMenu> daftarBahan = (data['bahan'] as List? ?? [])
        .map((item) => BahanMenu.fromMap(item))
        .toList();

    return Menu(
      id: doc.id,
      namaMenu: data['namaMenu'] ?? '',
      harga: data['harga'] ?? 0,
      deskripsi: data['deskripsi'] ?? '',
      bahan: daftarBahan,
      hpp: (data['hpp'] as num? ?? 0).toDouble(), // <-- AMBIL DATA BARU
      markup: (data['markup'] as num? ?? 0).toDouble(), // <-- AMBIL DATA BARU
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaMenu': namaMenu,
      'harga': harga,
      'deskripsi': deskripsi,
      'bahan': bahan.map((b) => b.toMap()).toList(),
      'hpp': hpp, // <-- SIMPAN DATA BARU
      'markup': markup, // <-- SIMPAN DATA BARU
    };
  }
}