import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pesanan_model.dart';
import '../models/menu_model.dart';
// Hapus import BahanBaku, karena kita hanya perlu Menu di sini
// import '../models/bahan_baku_model.dart'; 

class DetailPesananPage extends StatefulWidget {
  final String pesananId;
  const DetailPesananPage({super.key, required this.pesananId});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateStatus(String newStatus, String pesananId) async {
    try {
      await _firestore
          .collection('pesanan')
          .doc(pesananId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan berhasil diubah menjadi "$newStatus"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('pesanan').doc(widget.pesananId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }

          final pesanan = Pesanan.fromFirestore(
              snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
          final currency = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("Status Pesanan", _buildStatusSection(pesanan)),
                _buildSection(
                    "Informasi Pelanggan", _buildPelangganSection(pesanan)),
                _buildSection("Item yang Dipesan", _buildItemsSection(pesanan)),
                _buildSection("Ringkasan Pembayaran",
                    _buildBiayaSection(pesanan, currency)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(Pesanan pesanan) {
    final statuses = ['Baru', 'Diproses', 'Selesai', 'Batal'];
    return DropdownButtonFormField<String>(
      value: pesanan.status,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: statuses.map((String status) {
        return DropdownMenuItem<String>(value: status, child: Text(status));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null && newValue != pesanan.status) {
          _updateStatus(newValue, pesanan.id);
        }
      },
    );
  }

  // --- Memperbaiki implementasi yang kosong ---
  Widget _buildPelangganSection(Pesanan pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow("Nama:", pesanan.namaPelanggan),
        _detailRow("Telepon:", pesanan.noTelepon),
        _detailRow("Alamat:", pesanan.alamat),
        _detailRow(
            "Tanggal Kirim:",
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                .format(pesanan.tanggalKirim)),
        if (pesanan.catatan.isNotEmpty) _detailRow("Catatan:", pesanan.catatan),
      ],
    );
  }

  Widget _buildItemsSection(Pesanan pesanan) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pesanan.items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final itemPesanan = pesanan.items[index];
        return _buildMenuItemWithIngredients(itemPesanan);
      },
    );
  }

  // --- Memperbaiki implementasi yang kosong ---
  Widget _buildBiayaSection(Pesanan pesanan, NumberFormat currency) {
    return Column(
      children: [
        _detailRow("Subtotal:", currency.format(pesanan.subTotal)),
        _detailRow("Diskon:", currency.format(pesanan.diskon)),
        const Divider(height: 20, thickness: 1),
        _detailRow("Grand Total:", currency.format(pesanan.grandTotal),
            isBold: true),
      ],
    );
  }

  // --- Memperbaiki implementasi yang kosong ---
  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- INI ADALAH BAGIAN UTAMA YANG DIPERBAIKI ---
  Widget _buildMenuItemWithIngredients(dynamic itemPesanan) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ExpansionTile(
      title: Text(
        '${itemPesanan.jumlah}x ${itemPesanan.namaMenu}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(currency.format(itemPesanan.harga * itemPesanan.jumlah)),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('menu').doc(itemPesanan.menuId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Gagal memuat data bahan.',
                  style: TextStyle(color: Colors.red));
            }

            // PERBAIKAN 1: Menggunakan Menu.fromFirestore, bukan BahanBaku.fromFirestore
            final menu = Menu.fromFirestore(
                snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);

            if (menu.bahan.isEmpty) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tidak ada data bahan untuk menu ini.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bahan yang diperlukan:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                // PERBAIKAN 2: Menggunakan nama properti yang benar dari model BahanMenu
                ...menu.bahan.map((bahan) {
                  return Text(
                      '- ${bahan.namaBahan}: ${bahan.kuantitasPakai} ${bahan.satuanPakai}');
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }
}