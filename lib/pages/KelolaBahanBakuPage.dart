import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dapoer_ami/models/bahan_baku_model.dart';
import 'package:dapoer_ami/pages/TambahEditBahanBakuPage.dart';
import 'package:dapoer_ami/widgets/DetailBahanBakuContent.dart';

// lib/pages/kelola_bahan_baku_page.dart



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

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menghapus
  void _showDeleteConfirmationDialog(BahanBaku bahanBaku) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
              'Apakah Anda yakin ingin menghapus bahan baku "${bahanBaku.nama}"?'),
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
                  await _firestore.collection('bahan_baku').doc(bahanBaku.id).delete();
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bahan baku berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus bahan baku: $e'),
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
        title: const Text('Kelola Bahan Baku'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bahan_baku').orderBy('nama').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada bahan baku.\nSilakan tambahkan data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              BahanBaku bahanBaku = BahanBaku.fromFirestore(
                  snapshot.data!.docs[index] as DocumentSnapshot<Map<String, dynamic>>);
              
              // Format harga per unit agar lebih informatif
              final formattedHargaPerUnit = NumberFormat.currency(
                locale: 'id_ID', 
                symbol: 'Rp ', 
                decimalDigits: 2
              ).format(bahanBaku.hargaPerUnit);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.4, // Ukuran bisa lebih kecil
                          minChildSize: 0.2,
                          maxChildSize: 0.6,
                          builder: (context, scrollController) {
                            return SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                                child: DetailBahanBakuContent(bahanBaku: bahanBaku),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            // padding: const EdgeInsets.only(left: 8.0),
                            
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(bahanBaku.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Harga Beli: ${_currencyFormatter.format(bahanBaku.hargaBeli)} / ${bahanBaku.kuantitasBeli} ${bahanBaku.satuanBeli}',
                                ),
                                // Text(
                                //   'Harga per ${bahanBaku.satuanBeli}: $formattedHargaPerUnit',
                                //   style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                // ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              tooltip: 'Edit Bahan Baku',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TambahEditBahanBakuPage(bahanBaku: bahanBaku)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Hapus Bahan Baku',
                              onPressed: () => _showDeleteConfirmationDialog(bahanBaku),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahEditBahanBakuPage()),
          );
        },
        tooltip: 'Tambah Bahan Baku',
        child: const Icon(Icons.add),
      ),
    );
  }
}
