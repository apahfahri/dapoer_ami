import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:dapoer_ami/models/pesanan_model.dart';
import 'package:dapoer_ami/pages/KelolaBahanBakuPage.dart';
import 'package:dapoer_ami/pages/KelolaMenuPage.dart';
import 'package:dapoer_ami/pages/KelolaPesananPage.dart';
import 'package:dapoer_ami/pages/TambahEditPesananPage.dart';
import 'package:dapoer_ami/pages/LoginPage.dart';
import 'package:dapoer_ami/pages/RiwayatPesananPage.dart';
import 'package:dapoer_ami/widgets/DetailPesananContent.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- LOGIKA TIMER DIHAPUS ---

  bool _isLoadingStats = true;
  int _pesananHariIni = 0;
  int _perluDiproses = 0;
  int _selesaiBulanIni = 0;

  @override
  void initState() {
    super.initState();
    // Tetap panggil data saat halaman pertama kali dimuat
    _fetchStatistikData();
  }

  // --- dispose() tidak lagi diperlukan untuk timer, bisa dihapus atau dibiarkan kosong ---
  @override
  void dispose() {
    super.dispose();
  }

  // --- Fungsi fetch data tidak perlu diubah, parameter showLoading tetap berguna ---
  Future<void> _fetchStatistikData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoadingStats = true);
    }

    try {
      final results = await Future.wait([
        _getPesananHariIniCount(),
        _getPerluDiprosesCount(),
        _getSelesaiBulanIniCount(),
      ]);
      if (mounted) {
        setState(() {
          _pesananHariIni = results[0];
          _perluDiproses = results[1];
          _selesaiBulanIni = results[2];
        });
      }
    } catch (e) {
      print("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<int> _getPesananHariIniCount() async {
    final now = DateTime.now();
    final startOfToday =
        Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endOfToday =
        Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1));
    final snapshot = await _firestore
        .collection('pesanan')
        .where('tanggalKirim', isGreaterThanOrEqualTo: startOfToday)
        .where('tanggalKirim', isLessThan: endOfToday)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPerluDiprosesCount() async {
    final snapshot = await _firestore
        .collection('pesanan')
        .where('status', whereIn: ['Baru', 'Diproses'])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getSelesaiBulanIniCount() async {
    final now = DateTime.now();
    final startOfMonth = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final endOfMonth = Timestamp.fromDate(DateTime(now.year, now.month + 1, 1));
    final snapshot = await _firestore
        .collection('pesanan')
        .where('status', isEqualTo: 'Selesai')
        .where('tanggalKirim', isGreaterThanOrEqualTo: startOfMonth)
        .where('tanggalKirim', isLessThan: endOfMonth)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

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
      drawer: _buildAppDrawer(),
      appBar: AppBar(
        title: const Text('Dapoer Ami Catering'),
        centerTitle: false,
        // --- PERUBAHAN UTAMA: Menambahkan tombol refresh di sini ---
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchStatistikData(showLoading: true),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        // Pull-to-refresh tetap memanggil fungsi yang sama
        onRefresh: () => _fetchStatistikData(showLoading: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Berikut ringkasan aktivitas catering Anda.'),
                const SizedBox(height: 24),
                _buildStatistikSection(),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 28, color: Colors.white),
                    label: const Text('Tambah Pesanan Baru', 
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF4CAF50), // Warna hijau
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TambahEditPesananPage())),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pesanan Terbaru',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const KelolaPesananPage())),
                        child: const Text('Lihat Semua'))
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

  // Sisa kode tidak ada perubahan...
  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Dapoer Ami',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text('Manajemen Catering',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(
              icon: Icons.assignment_outlined,
              text: 'Kelola Pesanan',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const KelolaPesananPage()));
              }),
          _buildDrawerItem(
              icon: Icons.restaurant_menu_outlined,
              text: 'Kelola Menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const KelolaMenuPage()));
              }),
          _buildDrawerItem(
              icon: Icons.inventory_2_outlined,
              text: 'Kelola Bahan Baku',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const KelolaBahanBakuPage()));
              }),
          _buildDrawerItem(
            icon: Icons.history_edu_outlined,
            text: 'Riwayat & Pendapatan',
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RiwayatPesananPage()));
            },
          ),
          const Divider(),
          _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _logout();
              }),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(text), onTap: onTap);
  }

  Widget _buildStatistikSection() {
    final List<Widget> statCards = [
      _buildStatCard('Hari Ini', _pesananHariIni, Icons.today, Colors.blue,
          _isLoadingStats),
      _buildStatCard('Pending', _perluDiproses, Icons.pending_actions,
          Colors.orange, _isLoadingStats),
      _buildStatCard('Selesai/Bln', _selesaiBulanIni, Icons.check_circle,
          Colors.green, _isLoadingStats),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) => statCards[index],
    );
  }

  Widget _buildStatCard(
      String title, int value, IconData icon, Color color, bool isLoading) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const Spacer(),
            SizedBox(
              height: 30,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3)))
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value.toString(),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDaftarPesananTerbaru() {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pesanan')
          .orderBy('tanggalPesan', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada pesanan.',
                      style: TextStyle(color: Colors.grey))));
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
                  child:
                      Icon(Icons.receipt_long, color: _getStatusColor(status)),
                ),
                title: Text(data['namaPelanggan'] ?? 'Tanpa Nama',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Kirim: ${DateFormat('dd MMM yy', 'id_ID').format((data['tanggalKirim'] as Timestamp).toDate())} - ${currencyFormatter.format(data['grandTotal'] ?? 0)}'),
                trailing: Chip(
                  label: Text(status,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: _getStatusColor(status),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onTap: () {
                  final pesanan = Pesanan.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16))),
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
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 48),
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
}
