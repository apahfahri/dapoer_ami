// lib/models/bahan_baku_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BahanBaku {
  final String id;
  final String nama;
  final double hargaBeli;
  final double kuantitasBeli;
  final String satuanBeli; // Contoh: kg, liter, butir, ikat

  BahanBaku({
    required this.id,
    required this.nama,
    required this.hargaBeli,
    required this.kuantitasBeli,
    required this.satuanBeli,
  });

  // Fungsi untuk menghitung harga per unit terkecil (misal per gram atau per ml)
  double get hargaPerUnit {
    if (kuantitasBeli == 0) return 0;
    return hargaBeli / kuantitasBeli;
  }

  factory BahanBaku.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return BahanBaku(
      id: doc.id,
      nama: data['nama'] ?? '',
      hargaBeli: (data['hargaBeli'] as num).toDouble(),
      kuantitasBeli: (data['kuantitasBeli'] as num).toDouble(),
      satuanBeli: data['satuanBeli'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'hargaBeli': hargaBeli,
      'kuantitasBeli': kuantitasBeli,
      'satuanBeli': satuanBeli,
    };
  }
}