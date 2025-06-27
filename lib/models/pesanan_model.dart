import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_pesanan_model.dart';

class Pesanan {
  final String id;
  final String namaPelanggan;
  final String noTelepon;
  final String alamat;
  final DateTime tanggalPesan;
  final DateTime tanggalKirim;
  String status;
  final String catatan;
  final List<ItemPesanan> items;
  final int subTotal;
  final int diskon;
  final int grandTotal;

  Pesanan({
    required this.id,
    required this.namaPelanggan,
    required this.noTelepon,
    required this.alamat,
    required this.tanggalPesan,
    required this.tanggalKirim,
    required this.status,
    required this.catatan,
    required this.items,
    required this.subTotal,
    required this.diskon,
    required this.grandTotal,
  });

  // Dari Firestore ke Object
  factory Pesanan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return Pesanan(
      id: doc.id,
      namaPelanggan: data['namaPelanggan'],
      noTelepon: data['noTelepon'],
      alamat: data['alamat'],
      tanggalPesan: (data['tanggalPesan'] as Timestamp).toDate(),
      tanggalKirim: (data['tanggalKirim'] as Timestamp).toDate(),
      status: data['status'],
      catatan: data['catatan'] ?? '',
      // Mengubah list of map dari firestore menjadi list of ItemPesanan
      items: (data['items'] as List<dynamic>)
          .map((itemMap) => ItemPesanan.fromMap(itemMap))
          .toList(),
      subTotal: data['subTotal'],
      diskon: data['diskon'],
      grandTotal: data['grandTotal'],
    );
  }

  // Dari Object ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'namaPelanggan': namaPelanggan,
      'noTelepon': noTelepon,
      'alamat': alamat,
      'tanggalPesan': Timestamp.fromDate(tanggalPesan),
      'tanggalKirim': Timestamp.fromDate(tanggalKirim),
      'status': status,
      'catatan': catatan,
      // Mengubah list of ItemPesanan menjadi list of map
      'items': items.map((item) => item.toMap()).toList(),
      'subTotal': subTotal,
      'diskon': diskon,
      'grandTotal': grandTotal,
    };
  }
}