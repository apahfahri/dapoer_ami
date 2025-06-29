// lib/pages/kelola_menu_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';
import '../pages/TambahEditMenuPage.dart';
import '../widgets/DetailMenuContent.dart';

class KelolaMenuPage extends StatefulWidget {
  const KelolaMenuPage({super.key});

  @override
  State<KelolaMenuPage> createState() => _KelolaMenuPageState();
}

class _KelolaMenuPageState extends State<KelolaMenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- PERUBAHAN 1: Tambahkan state untuk pencarian ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog(Menu menu) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
              'Apakah Anda yakin ingin menghapus menu "${menu.namaMenu}"? Aksi ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () async {
                try {
                  await _firestore.collection('menu').doc(menu.id).delete();
                  Navigator.of(ctx).pop(); // Tutup dialog
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menu berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus menu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
      ),
      // --- PERUBAHAN 2: Struktur body diubah menjadi Column ---
      body: Column(
        children: [
          // Widget untuk search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Menu',
                hintText: 'Ketik nama menu...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Widget untuk menampilkan daftar, dibungkus Expanded
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('menu').orderBy('namaMenu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada menu.\nSilakan tambahkan menu baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // --- PERUBAHAN 3: Logika untuk memfilter hasil ---
                final allDocs = snapshot.data!.docs;
                final filteredDocs = _searchQuery.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final menu = Menu.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                        return menu.namaMenu.toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'Menu dengan nama "$_searchQuery" tidak ditemukan.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    Menu menu = Menu.fromFirestore(
                        filteredDocs[index] as DocumentSnapshot<Map<String, dynamic>>);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (context) {
                              return DraggableScrollableSheet(
                                expand: false,
                                initialChildSize: 0.5,
                                minChildSize: 0.3,
                                maxChildSize: 0.8,
                                builder: (context, scrollController) {
                                  return SingleChildScrollView(
                                    controller: scrollController,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                                      child: DetailMenuContent(menu: menu),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(menu.namaMenu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text('Harga Jual: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(menu.harga)}'),
                                      Text('HPP: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(menu.hpp)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                    tooltip: 'Edit Menu',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => TambahEditMenuPage(menu: menu)),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Hapus Menu',
                                    onPressed: () => _showDeleteConfirmationDialog(menu),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahEditMenuPage()),
          );
        },
        tooltip: 'Tambah Menu Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}
