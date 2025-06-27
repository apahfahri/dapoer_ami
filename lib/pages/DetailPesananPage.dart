import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pesanan_model.dart';
import '../models/menu_model.dart';
// import '../models/bahan_menu_model.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan berhasil diubah menjadi "$newStatus"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FUNGSI BARU DITAMBAHKAN: UNTUK MENGHITUNG DAN MENJUMLAHKAN BAHAN ---
  Future<Map<String, double>> _calculateTotalIngredients(
      Pesanan pesanan) async {
    Map<String, double> aggregatedIngredients = {};

    for (var itemPesanan in pesanan.items) {
      DocumentSnapshot menuDoc =
          await _firestore.collection('menu').doc(itemPesanan.menuId).get();

      if (menuDoc.exists) {
        final menuData = Menu.fromFirestore(
            menuDoc as DocumentSnapshot<Map<String, dynamic>>);

        for (var bahanResep in menuData.bahan) {
          double totalKuantitas =
              bahanResep.kuantitasPakai * itemPesanan.jumlah;
          String key = '${bahanResep.namaBahan} (${bahanResep.satuanPakai})';

          if (aggregatedIngredients.containsKey(key)) {
            aggregatedIngredients[key] =
                aggregatedIngredients[key]! + totalKuantitas;
          } else {
            aggregatedIngredients[key] = totalKuantitas;
          }
        }
      }
    }
    return aggregatedIngredients;
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

                // --- BAGIAN BARU DITAMBAHKAN DI SINI ---
                _buildKebutuhanBahanSection(pesanan),

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

  // --- WIDGET BARU DITAMBAHKAN: UNTUK MENAMPILKAN TOTAL KEBUTUHAN BAHAN ---
  Widget _buildKebutuhanBahanSection(Pesanan pesanan) {
    return _buildSection(
      "Total Kebutuhan Bahan Baku",
      FutureBuilder<Map<String, double>>(
        future: _calculateTotalIngredients(pesanan),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text("Tidak ada bahan yang dibutuhkan.");
          }

          final ingredients = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ingredients.entries.map((entry) {
              final formattedValue = entry.value
                  .toStringAsFixed(1)
                  .replaceAll(RegExp(r'\.0$'), '');
              final parts = entry.key.split(' (');
              final namaBahan = parts[0];
              final satuan = parts[1].replaceAll(')', '');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('- $namaBahan'),
                    Text('$formattedValue $satuan',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
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

  Widget _buildMenuItemWithIngredients(dynamic itemPesanan) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ExpansionTile(
      // Judul utama tetap sama
      title: Text(
        '${itemPesanan.jumlah}x ${itemPesanan.namaMenu}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(currency.format(itemPesanan.harga * itemPesanan.jumlah)),
      childrenPadding: const EdgeInsets.fromLTRB(
          16, 0, 16, 16), // Padding diatur agar lebih rapi
      // 'children' akan diisi oleh FutureBuilder yang mengambil data bahan
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('menu').doc(itemPesanan.menuId).get(),
          builder: (context, snapshot) {
            // Saat data sedang dimuat
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
            // Jika terjadi error
            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Text('Gagal memuat data bahan.',
                  style: TextStyle(color: Colors.red));
            }

            final menu = Menu.fromFirestore(
                snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);

            if (menu.bahan.isEmpty) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tidak ada data bahan untuk menu ini.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              );
            }

            // --- PERBAIKAN UTAMA ADA DI SINI ---
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Total bahan untuk item ini:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                // Map over the ingredients and create a list of widgets
                ...menu.bahan.map((bahan) {
                  // 1. Hitung total kuantitas untuk bahan ini
                  final totalKuantitas =
                      bahan.kuantitasPakai * itemPesanan.jumlah;

                  // 2. Format angka agar tidak menampilkan desimal yang tidak perlu (misal: 5.0 -> 5)
                  final formattedKuantitas = totalKuantitas
                      .toStringAsFixed(2)
                      .replaceAll(RegExp(r'([.,]00)$'), '');

                  // 3. Tampilkan hasil perhitungan
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                        '- ${bahan.namaBahan}: $formattedKuantitas ${bahan.satuanPakai}'),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }
}
