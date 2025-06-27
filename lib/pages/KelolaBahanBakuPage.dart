import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dapoer_ami/models/bahan_baku_model.dart';
import 'package:dapoer_ami/pages/TambahEditBahanBakuPage.dart';

class KelolaBahanBakuPage extends StatefulWidget {
  const KelolaBahanBakuPage({super.key});

  @override
  State<KelolaBahanBakuPage> createState() => _KelolaBahanBakuPageState();
}

class _KelolaBahanBakuPageState extends State<KelolaBahanBakuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _deleteMenu(BahanBaku bahanbaku) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus bahan baku "${bahanbaku.nama}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await _firestore.collection('bahan_baku').doc(bahanbaku.id).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bahan baku berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
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
        title: const Text('Kelola Bahan Baku'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bahan_baku').orderBy('nama').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada bahan baku. Silakan tambahkan.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              BahanBaku bahanBaku = BahanBaku.fromFirestore(snapshot.data!.docs[index] as DocumentSnapshot<Map<String, dynamic>>);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(bahanBaku.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_currencyFormatter.format(bahanBaku.hargaPerUnit)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TambahEditBahanBakuPage(bahanBaku: bahanBaku)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMenu(bahanBaku),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahEditBahanBakuPage()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}