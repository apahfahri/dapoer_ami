// lib/pages/riwayat_pesanan_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pesanan_model.dart';
import '../widgets/DetailPesananContent.dart';

class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  @override
  State<RiwayatPesananPage> createState() => _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Membuat query untuk mengambil pesanan yang hanya berstatus 'Selesai'
    final queryPesananSelesai = _firestore
        .collection('pesanan')
        .where('status', isEqualTo: 'Selesai')
        .orderBy('tanggalKirim', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat & Pendapatan'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: queryPesananSelesai.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada pesanan yang selesai.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final pesananDocs = snapshot.data!.docs;
          
          // --- Logika untuk menghitung total pendapatan ---
          double totalPendapatan = 0;
          for (var doc in pesananDocs) {
            final data = doc.data() as Map<String, dynamic>;
            totalPendapatan += (data['grandTotal'] as num? ?? 0);
          }

          return Column(
            children: [
              // --- Kartu untuk menampilkan Total Pendapatan ---
              _buildTotalPendapatanCard(totalPendapatan),

              // --- Daftar Riwayat Pesanan ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  itemCount: pesananDocs.length,
                  itemBuilder: (context, index) {
                    final pesanan = Pesanan.fromFirestore(pesananDocs[index] as DocumentSnapshot<Map<String, dynamic>>);
                    return _buildRiwayatItem(pesanan);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget untuk kartu ringkasan pendapatan
  Widget _buildTotalPendapatanCard(double total) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.green[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Total Pendapatan Terkumpul',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk setiap item dalam daftar riwayat
  Widget _buildRiwayatItem(Pesanan pesanan) {
     final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
     final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: ListTile(
        title: Text(pesanan.namaPelanggan, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Selesai pada: ${dateFormatter.format(pesanan.tanggalKirim)}'),
        trailing: Text(currencyFormatter.format(pesanan.grandTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: () {
          // Menampilkan detail menggunakan BottomSheet saat item diklik
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                      child: DetailPesananContent(pesanan: pesanan),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
