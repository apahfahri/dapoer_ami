// lib/widgets/detail_pesanan_content.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pesanan_model.dart';
import '../models/menu_model.dart';

// Widget ini HANYA FOKUS menampilkan data Pesanan yang sudah ada.
class DetailPesananContent extends StatelessWidget {
  final Pesanan pesanan;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DetailPesananContent({super.key, required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Penting untuk Dialog/Bottom Sheet
      children: [
        // Kita tidak perlu Card/Section lagi karena sudah di dalam Dialog
        _buildPelangganSection(pesanan),
        const Divider(height: 24),
        _buildItemsSection(pesanan),
        const Divider(height: 24),
        _buildBiayaSection(pesanan, currency),
      ],
    );
  }

  // Helper widget untuk detail pelanggan
  Widget _buildPelangganSection(Pesanan pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Informasi Pelanggan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _detailRow("Nama:", pesanan.namaPelanggan),
        _detailRow("Telepon:", pesanan.noTelepon),
        _detailRow("Alamat:", pesanan.alamat),
        _detailRow("Tanggal Kirim:", DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(pesanan.tanggalKirim)),
        if (pesanan.catatan.isNotEmpty) _detailRow("Catatan:", pesanan.catatan),
      ],
    );
  }

  // Helper widget untuk item pesanan
  Widget _buildItemsSection(Pesanan pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Item yang Dipesan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pesanan.items.length,
          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
          itemBuilder: (context, index) {
            return _buildMenuItemWithIngredients(pesanan.items[index]);
          },
        ),
      ],
    );
  }

  // Helper widget untuk rincian biaya
  Widget _buildBiayaSection(Pesanan pesanan, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Text("Ringkasan Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _detailRow("Subtotal:", currency.format(pesanan.subTotal)),
        _detailRow("Diskon:", currency.format(pesanan.diskon)),
        const Divider(height: 16, thickness: 1),
        _detailRow("Grand Total:", currency.format(pesanan.grandTotal), isBold: true),
      ],
    );
  }

  // Helper widget untuk baris detail
  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- BAGIAN UTAMA YANG DIPERBAIKI ---
  Widget _buildMenuItemWithIngredients(dynamic itemPesanan) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('${itemPesanan.jumlah}x ${itemPesanan.namaMenu}', style: const TextStyle(fontWeight: FontWeight.bold)),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('menu').doc(itemPesanan.menuId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Data bahan tidak ditemukan.');
            }
            
            // PERBAIKAN 1: Menggunakan Menu.fromFirestore, bukan BahanBaku.fromFirestore
            final menu = Menu.fromFirestore(snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);

            if (menu.bahan.isEmpty) {
              return const Align(alignment: Alignment.centerLeft, child: Text('Tidak ada data bahan.', style: TextStyle(fontStyle: FontStyle.italic)));
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bahan-bahan:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                // PERBAIKAN 2: Menggunakan nama properti yang benar (kuantitasPakai, satuanPakai)
                ...menu.bahan.map((bahan) => Text('- ${bahan.namaBahan}: ${bahan.kuantitasPakai} ${bahan.satuanPakai}')).toList(),
              ],
            );
          },
        ),
      ],
    );
  }
}
