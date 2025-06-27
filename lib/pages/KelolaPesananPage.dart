import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pesanan_model.dart';
import 'package:dapoer_ami/pages/DetailPesananPage.dart';

class KelolaPesananPage extends StatefulWidget {
  const KelolaPesananPage({super.key});

  @override
  State<KelolaPesananPage> createState() => _KelolaPesananPageState();
}

class _KelolaPesananPageState extends State<KelolaPesananPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = [
    'Semua',
    'Baru',
    'Diproses',
    'Selesai',
    'Batal'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statuses.map((String status) => Tab(text: status)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((String status) {
          // Untuk tab "Semua", kita tidak memfilter berdasarkan status (null)
          return _PesananListView(status: status == 'Semua' ? null : status);
        }).toList(),
      ),
    );
  }
}

// Widget terpisah untuk menampilkan daftar pesanan berdasarkan status
class _PesananListView extends StatelessWidget {
  final String? status;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  _PesananListView({super.key, this.status});

  String _formatTanggal(DateTime tanggal) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.orange;
      case 'batal':
        return Colors.red;
      case 'baru':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Membuat query ke firestore
    Query query = _firestore
        .collection('pesanan')
        .orderBy('tanggalKirim', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('Tidak ada pesanan dengan status "$status".'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            Pesanan pesanan = Pesanan.fromFirestore(snapshot.data!.docs[index]
                as DocumentSnapshot<Map<String, dynamic>>);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(pesanan.namaPelanggan,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kirim: ${_formatTanggal(pesanan.tanggalKirim)}'),
                    Text(_currencyFormatter.format(pesanan.grandTotal)),
                  ],
                ),
                trailing: Chip(
                  label: Text(pesanan.status,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _getStatusColor(pesanan.status),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailPesananPage(pesananId: pesanan.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
