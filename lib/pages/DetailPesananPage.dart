import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/pesanan_model.dart';
import '../models/menu_model.dart';
// import '../models/bahan_menu_model.dart';
import '../services/pdf_invoice_services.dart';

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

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: title.contains("Batalkan")
                    ? Colors.red
                    : Theme.of(context).primaryColor,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
              child: const Text(
                'Ya, Lanjutkan',
                style: TextStyle(color: Colors.white),
                // selectionColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _exportToPdf(Pesanan pesanan) async {
    final pdfService = PdfInvoiceService(pesanan: pesanan);
    final fileName = pdfService.generateFileName();
    final pdfBytes = await pdfService.createInvoice();

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        actions: [
          // Tombol ekspor struk tetap ada dan bisa digunakan kapan saja
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('pesanan')
                .doc(widget.pesananId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const IconButton(
                    icon: Icon(Icons.picture_as_pdf), onPressed: null);
              }
              final pesanan = Pesanan.fromFirestore(
                  snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Ekspor ke PDF',
                onPressed: () => _exportToPdf(pesanan),
              );
            },
          ),
        ],
      ),
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
                // --- PERUBAHAN UTAMA ADA DI SINI ---
                _buildSection(
                    "Aksi & Status Pesanan", _buildStatusSection(pesanan)),
                _buildSection("Informasi Pesanan",
                    _buildInformasiPesananSection(pesanan)),
                _buildSection(
                    "Informasi Pelanggan", _buildPelangganSection(pesanan)),
                _buildKebutuhanBahanSection(pesanan),
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

  // --- WIDGET BAGIAN STATUS YANG DIROMBAK TOTAL ---
  Widget _buildStatusSection(Pesanan pesanan) {
    // Tampilan berdasarkan status pesanan saat ini
    switch (pesanan.status) {
      case 'Baru':
        return Column(
          children: [
            _buildStatusChip('Baru', Colors.blue),
            const SizedBox(height: 16),
            const Text('Pesanan ini menunggu konfirmasi Anda.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Batalkan Pesanan?',
                        content:
                            'Apakah Anda yakin ingin membatalkan pesanan ini?',
                        onConfirm: () => _updateStatus('Batal', pesanan.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Konfirmasi'),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Konfirmasi Pesanan?',
                        content:
                            'Konfirmasi akan mengubah status menjadi "Diproses" dan pesanan siap dibuat.',
                        onConfirm: () => _updateStatus('Diproses', pesanan.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case 'Diproses':
        return Column(
          children: [
            _buildStatusChip('Diproses', Colors.orange),
            const SizedBox(height: 16),
            const Text(
                'Pesanan sedang dalam proses pembuatan. Klik selesai jika sudah siap diantar.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Batalkan Pesanan?',
                        content:
                            'Apakah Anda yakin ingin membatalkan pesanan yang sedang diproses ini?',
                        onConfirm: () => _updateStatus('Batal', pesanan.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Selesai',style: TextStyle(color: Colors.white),),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green,iconColor: Colors.white),
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Selesaikan Pesanan?',
                        content:
                            'Pesanan akan ditandai sebagai "Selesai" dan struk akan dicetak.',
                        onConfirm: () {
                          _updateStatus('Selesai', pesanan.id);
                          _exportToPdf(pesanan);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case 'Selesai':
        return Center(child: _buildStatusChip('Selesai', Colors.green));

      case 'Batal':
        return Center(child: _buildStatusChip('Dibatalkan', Colors.red));

      default:
        return Center(child: Text('Status tidak diketahui: ${pesanan.status}'));
    }
  }

  // Helper widget untuk membuat "chip" status agar bisa dipakai ulang
  Widget _buildStatusChip(String status, Color color) {
    return Chip(
      label: Text(status,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      labelStyle: const TextStyle(fontSize: 16),
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

  Widget _buildPelangganSection(Pesanan pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow("Nama:", pesanan.namaPelanggan),
        _detailRow("Telepon:", pesanan.noTelepon),
        _detailRow("Alamat:", pesanan.alamat),
      ],
    );
  }

  Widget _buildInformasiPesananSection(Pesanan pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow("No. Pesanan:", pesanan.id.substring(0, 8).toUpperCase()),
        _detailRow(
            "Tanggal Pesan:",
            DateFormat('EEEE, dd MMM yy', 'id_ID')
                .format(pesanan.tanggalPesan)),
        _detailRow(
            "Tanggal Kirim:",
            DateFormat('EEEE, dd MMM yy', 'id_ID')
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
