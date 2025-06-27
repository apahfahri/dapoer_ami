// lib/pages/kelola_menu_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';
import '../pages/TambahEditMenuPage.dart';

class KelolaMenuPage extends StatefulWidget {
  const KelolaMenuPage({super.key});

  @override
  State<KelolaMenuPage> createState() => _KelolaMenuPageState();
}

class _KelolaMenuPageState extends State<KelolaMenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menghapus
  void _showDeleteConfirmationDialog(Menu menu) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus menu "${menu.namaMenu}"? Aksi ini tidak dapat dibatalkan.'),
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
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data dari collection 'menu' dan mengurutkannya berdasarkan nama
        stream: _firestore.collection('menu').orderBy('namaMenu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Konversi data dari Firestore menjadi objek Menu
              Menu menu = Menu.fromFirestore(snapshot.data!.docs[index] as DocumentSnapshot<Map<String, dynamic>>);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(
                    menu.namaMenu,
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    'Harga Jual: ${_currencyFormatter.format(menu.harga)}\nHPP: ${_currencyFormatter.format(menu.hpp)}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                        tooltip: 'Edit Menu',
                        onPressed: () {
                          // Navigasi ke halaman edit dengan membawa data menu yang dipilih
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TambahEditMenuPage(menu: menu)),
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah menu (tanpa membawa data)
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
