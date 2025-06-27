import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/item_pesanan_model.dart';
import '../models/menu_model.dart';

class TambahEditPesananPage extends StatefulWidget {
  // Nanti bisa ditambahkan `final Pesanan? pesanan;` untuk mode edit
  const TambahEditPesananPage({super.key});

  @override
  State<TambahEditPesananPage> createState() => _TambahEditPesananPageState();
}

class _TambahEditPesananPageState extends State<TambahEditPesananPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();
  final _catatanController = TextEditingController();

  // State
  DateTime? _tanggalKirim;
  final List<ItemPesanan> _items = [];
  int _subTotal = 0;
  int _diskon = 0;
  int _grandTotal = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // --- LOGIKA UTAMA ---

  void _hitungTotal() {
    int currentSubTotal = 0;
    int totalItem = 0;

    for (var item in _items) {
      currentSubTotal += item.harga * item.jumlah;
      totalItem += item.jumlah;
    }

    int currentDiskon = 0;
    // LOGIKA DISKON: Jika total item lebih dari 100, dapat diskon 50%
    if (totalItem > 100) {
      currentDiskon = (currentSubTotal * 0.5).round();
    }
    
    setState(() {
      _subTotal = currentSubTotal;
      _diskon = currentDiskon;
      _grandTotal = currentSubTotal - currentDiskon;
    });
  }

  void _tambahItem(ItemPesanan item) {
    // Cek apakah item sudah ada, jika ya, tambahkan jumlahnya
    var existingItemIndex = _items.indexWhere((i) => i.menuId == item.menuId);
    if (existingItemIndex != -1) {
      setState(() {
        _items[existingItemIndex].jumlah += item.jumlah;
      });
    } else {
      setState(() {
        _items.add(item);
      });
    }
    _hitungTotal();
  }

  void _hapusItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _hitungTotal();
  }

  Future<void> _savePesanan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalKirim == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal kirim harus diisi!')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan tidak boleh kosong!')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final dataPesanan = {
        'namaPelanggan': _namaController.text,
        'noTelepon': _teleponController.text,
        'alamat': _alamatController.text,
        'catatan': _catatanController.text,
        'tanggalPesan': Timestamp.now(),
        'tanggalKirim': Timestamp.fromDate(_tanggalKirim!),
        'status': 'Baru',
        'items': _items.map((item) => item.toMap()).toList(),
        'subTotal': _subTotal,
        'diskon': _diskon,
        'grandTotal': _grandTotal,
      };

      await FirebaseFirestore.instance.collection('pesanan').add(dataPesanan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil disimpan!'), backgroundColor: Colors.green,));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red,));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pesanan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Data Pelanggan'),
              _buildFormPelanggan(),
              const SizedBox(height: 24),

              _buildSectionTitle('Detail Pesanan'),
              _buildFormPesanan(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Item Pesanan'),
              _buildDaftarItem(),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item Menu'),
                  onPressed: () => _showPilihMenuDialog(),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Ringkasan Biaya'),
              _buildRingkasanBiaya(),
              const SizedBox(height: 32),

              _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(
                    onPressed: _savePesanan,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Simpan Pesanan'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFormPelanggan() {
    return Column(
      children: [
        TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Pelanggan'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
        const SizedBox(height: 8),
        TextFormField(controller: _teleponController, decoration: const InputDecoration(labelText: 'No. Telepon'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
        const SizedBox(height: 8),
        TextFormField(controller: _alamatController, decoration: const InputDecoration(labelText: 'Alamat Pengiriman'), maxLines: 2, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
      ],
    );
  }
  
  Widget _buildFormPesanan() {
    return Column(
      children: [
        ListTile(
          title: Text(_tanggalKirim == null ? 'Pilih Tanggal Kirim' : 'Tanggal Kirim: ${DateFormat('dd MMMM yyyy').format(_tanggalKirim!)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date != null) {
              setState(() => _tanggalKirim = date);
            }
          },
        ),
        TextFormField(controller: _catatanController, decoration: const InputDecoration(labelText: 'Catatan (Opsional)')),
      ],
    );
  }

  Widget _buildDaftarItem() {
    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada item ditambahkan.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(item.namaMenu),
            subtitle: Text('${item.jumlah} x ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.harga)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _hapusItem(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingkasanBiaya() {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(currency.format(_subTotal))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon'), Text(currency.format(_diskon), style: const TextStyle(color: Colors.green))]),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)), Text(currency.format(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  // DIALOG UNTUK MEMILIH MENU
  void _showPilihMenuDialog() {
    final jumlahController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Menu'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').orderBy('namaMenu').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final menu = Menu.fromFirestore(snapshot.data!.docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                    return ListTile(
                      title: Text(menu.namaMenu),
                      subtitle: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(menu.harga)),
                      onTap: () {
                        // Dialog untuk input jumlah
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Masukkan Jumlah'),
                            content: TextField(
                              controller: jumlahController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(ctx).pop()),
                              TextButton(
                                child: const Text('Tambah'),
                                onPressed: () {
                                  final jumlah = int.tryParse(jumlahController.text) ?? 0;
                                  if (jumlah > 0) {
                                    final item = ItemPesanan(menuId: menu.id, namaMenu: menu.namaMenu, harga: menu.harga, jumlah: jumlah);
                                    _tambahItem(item);
                                    Navigator.of(ctx).pop(); // Tutup dialog jumlah
                                    Navigator.of(context).pop(); // Tutup dialog pilih menu
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
        );
      },
    );
  }
}