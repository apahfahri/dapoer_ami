import 'package:dapoer_ami/models/pesanan_model.dart';
import 'package:dapoer_ami/pages/KelolaBahanBakuPage.dart';
import 'package:dapoer_ami/pages/KelolaMenuPage.dart';
import 'package:dapoer_ami/pages/KelolaPesananPage.dart';
import 'package:dapoer_ami/pages/TambahEditPesananPage.dart';
import 'package:dapoer_ami/pages/LoginPage.dart';
import 'package:dapoer_ami/pages/DetailPesananContent.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Instance untuk mengakses Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State untuk data statistik
  bool _isLoadingStats = true;
  int _pesananHariIni = 0;
  int _perluDiproses = 0;
  int _selesaiBulanIni = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatistikData();
  }

  // Fungsi untuk mengambil data statistik
  Future<void> _fetchStatistikData() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final results = await Future.wait([
        _getPesananHariIniCount(),
        _getPerluDiprosesCount(),
        _getSelesaiBulanIniCount(),
      ]);

      if (!mounted) return;
      setState(() {
        _pesananHariIni = results[0];
        _perluDiproses = results[1];
        _selesaiBulanIni = results[2];
      });
    } catch (e) {
      print("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // --- Query Statistik (tidak berubah) ---
  Future<int> _getPesananHariIniCount() async {
    final now = DateTime.now();
    final startOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1));

    final snapshot = await _firestore.collection('pesanan').where('tanggalKirim', isGreaterThanOrEqualTo: startOfToday).where('tanggalKirim', isLessThan: endOfToday).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPerluDiprosesCount() async {
    final snapshot = await _firestore.collection('pesanan').where('status', whereIn: ['Baru', 'Diproses']).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getSelesaiBulanIniCount() async {
    final now = DateTime.now();
    final startOfMonth = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final endOfMonth = Timestamp.fromDate(DateTime(now.year, now.month + 1, 1));

    final snapshot = await _firestore.collection('pesanan').where('status', isEqualTo: 'Selesai').where('tanggalKirim', isGreaterThanOrEqualTo: startOfMonth).where('tanggalKirim', isLessThan: endOfMonth).count().get();
    return snapshot.count ?? 0;
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dapoer Ami Catering'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStatistikData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Berikut ringkasan aktivitas catering Anda.'),
                const SizedBox(height: 24),
                _buildStatistikSection(),
                const SizedBox(height: 24),
                
                // --- BAGIAN INI TELAH DIUBAH ---
                _buildAksiCepatSection(), 
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pesanan Terbaru', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaPesananPage())),
                      child: const Text('Lihat Semua')
                    )
                  ],
                ),
                const SizedBox(height: 8),
                _buildDaftarPesananTerbaru(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistikSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Hari Ini', _pesananHariIni, Icons.today, Colors.blue, _isLoadingStats)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Perlu Diproses', _perluDiproses, Icons.pending_actions, Colors.orange, _isLoadingStats)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Selesai Bln Ini', _selesaiBulanIni, Icons.check_circle, Colors.green, _isLoadingStats)),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color, bool isLoading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            isLoading
                ? const SizedBox(height: 27, width: 27, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- METHOD INI YANG DIUBAH SECARA TOTAL ---
  Widget _buildAksiCepatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Agar tombol melebar penuh
      children: [
        // 1. Tombol utama di atas
        ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Tambah Pesanan Baru'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TambahEditPesananPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        // 2. Dua tombol sekunder di bawah dalam satu baris
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.assignment),
                label: const Text('Kelola Pesanan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KelolaPesananPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Kelola Menu'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KelolaMenuPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Kelola Bahan Baku'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KelolaBahanBakuPage()),
                  );
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDaftarPesananTerbaru() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('pesanan').orderBy('tanggalPesan', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Belum ada pesanan.', style: TextStyle(color: Colors.grey))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            var status = data['status'] ?? 'Baru';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(Icons.receipt_long, color: _getStatusColor(status)),
                ),
                title: Text(data['namaPelanggan'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Kirim: ${DateFormat('dd MMM', 'id_ID').format((data['tanggalKirim'] as Timestamp).toDate())} - ${currencyFormatter.format(data['grandTotal'] ?? 0)}'),
                trailing: Chip(
                  label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _getStatusColor(status),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onTap: () {
                  final pesanan = Pesanan.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return Colors.green;
      case 'diproses': return Colors.orange;
      case 'batal': return Colors.red;
      case 'baru':
      default: return Colors.blue;
    }
  }
}