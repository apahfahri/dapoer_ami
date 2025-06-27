import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import semua model dan utilitas yang dibutuhkan
import '../models/menu_model.dart';
import '../models/bahan_menu_model.dart';
import '../models/bahan_baku_model.dart';
import '../utils/unit_converter.dart';

class TambahEditMenuPage extends StatefulWidget {
  final Menu? menu;
  const TambahEditMenuPage({super.key, this.menu});

  @override
  State<TambahEditMenuPage> createState() => _TambahEditMenuPageState();
}

class _TambahEditMenuPageState extends State<TambahEditMenuPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _markupController = TextEditingController();

  final List<BahanMenu> _daftarBahanPakai = [];
  List<BahanBaku> _stokBahanBaku = []; 
  
  // --- Daftar Opsi Satuan untuk Dropdown ---
  final List<String> _satuanOptions = [
    'gram', 'kg', 'ml', 'liter', 'sdm', 'sdt', 'butir', 'buah', 'pcs', 'siung', 'ikat'
  ];

  double _hpp = 0;
  int _hargaJual = 0;
  bool _isLoading = false;
  bool _isBahanBakuLoading = true;
  late String _appBarTitle;

  @override
  void initState() {
    super.initState();
    _fetchBahanBaku(); 

    if (widget.menu != null) {
      _appBarTitle = 'Edit Menu';
      _namaController.text = widget.menu!.namaMenu;
      _deskripsiController.text = widget.menu!.deskripsi;
      _markupController.text = widget.menu!.markup.toStringAsFixed(0);
      _daftarBahanPakai.addAll(widget.menu!.bahan);
    } else {
      _appBarTitle = 'Tambah Menu Baru';
      _markupController.text = '100'; // Default markup 100%
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _markupController.dispose();
    super.dispose();
  }

  Future<void> _fetchBahanBaku() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bahan_baku').orderBy('nama').get();
      _stokBahanBaku = snapshot.docs.map((doc) => BahanBaku.fromFirestore(doc)).toList();
      if (widget.menu != null) {
        _hitungHppDanHargaJual();
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data bahan baku: $e')));
    } finally {
      if(mounted) setState(() => _isBahanBakuLoading = false);
    }
  }

  void _hitungHppDanHargaJual() {
    if (_stokBahanBaku.isEmpty) return;

    double totalHpp = 0;
    for (var bahanPakai in _daftarBahanPakai) {
      try {
        final bahanBaku = _stokBahanBaku.firstWhere((bb) => bb.id == bahanPakai.bahanBakuId);
        double hargaPerUnitBeli = bahanBaku.hargaBeli / bahanBaku.kuantitasBeli;
        double kuantitasPakaiDalamSatuanBeli = UnitConverter.convert(
          bahanPakai.kuantitasPakai,
          bahanPakai.satuanPakai,
          bahanBaku.satuanBeli,
        );
        double biayaBahan = hargaPerUnitBeli * kuantitasPakaiDalamSatuanBeli;
        totalHpp += biayaBahan;
      } catch (e) {
        print("Error menghitung HPP untuk ${bahanPakai.namaBahan}: $e");
      }
    }
    
    final markup = double.tryParse(_markupController.text) ?? 100.0;
    final hargaJual = totalHpp * (1 + (markup / 100));

    setState(() {
      _hpp = totalHpp;
      _hargaJual = hargaJual.ceil();
    });
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    _hitungHppDanHargaJual();

    try {
      final data = {
        'namaMenu': _namaController.text,
        'deskripsi': _deskripsiController.text,
        'bahan': _daftarBahanPakai.map((b) => b.toMap()).toList(),
        'hpp': _hpp,
        'markup': double.tryParse(_markupController.text) ?? 100,
        'harga': _hargaJual,
      };

      if (widget.menu != null) {
        await FirebaseFirestore.instance.collection('menu').doc(widget.menu!.id).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('menu').add(data);
      }
      
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil disimpan!'), backgroundColor: Colors.green));
         Navigator.of(context).pop();
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan menu: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- DIALOG INI YANG DIPERBAIKI ---
  void _showTambahBahanDialog() {
    BahanBaku? selectedBahanBaku;
    String? selectedSatuanPakai; // Variabel untuk state dropdown satuan pakai
    final kuantitasController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Bahan'),
          content: Form(
            key: dialogFormKey,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BahanBaku>(
                      isExpanded: true,
                      value: selectedBahanBaku,
                      hint: const Text('Pilih dari stok'),
                      items: _stokBahanBaku.map((bahan) {
                        return DropdownMenuItem<BahanBaku>(
                          value: bahan,
                          child: Text('${bahan.nama} (${bahan.satuanBeli})'),
                        );
                      }).toList(),
                      onChanged: (value) => setStateDialog(() => selectedBahanBaku = value),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    ),
                    TextFormField(
                      controller: kuantitasController,
                      decoration: const InputDecoration(labelText: 'Kuantitas Dipakai'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    // -- Ganti TextFormField dengan DropdownButtonFormField --
                    DropdownButtonFormField<String>(
                      value: selectedSatuanPakai,
                      hint: const Text('Pilih satuan pakai'),
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Satuan Dipakai'),
                      items: _satuanOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedSatuanPakai = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Satuan harus dipilih' : null,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final bahanPakaiBaru = BahanMenu(
                    bahanBakuId: selectedBahanBaku!.id,
                    namaBahan: selectedBahanBaku!.nama,
                    kuantitasPakai: double.tryParse(kuantitasController.text) ?? 0,
                    satuanPakai: selectedSatuanPakai!, // Ambil dari state dropdown
                  );
                  setState(() {
                    _daftarBahanPakai.add(bahanPakaiBaru);
                    _hitungHppDanHargaJual();
                  });
                  Navigator.pop(context);
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
    // ... Sisa kode build tidak ada perubahan signifikan ...
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: _isBahanBakuLoading 
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 8), Text("Memuat data bahan baku...")]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Menu'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi Singkat'), maxLines: 3),
                  const SizedBox(height: 24),
                  
                  _buildBahanSection(),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kalkulasi Harga Jual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          Text('Total Harga Pokok (HPP): ${currencyFormatter.format(_hpp)}'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _markupController,
                            decoration: const InputDecoration(labelText: 'Markup Keuntungan (%)', helperText: 'Contoh: 100 untuk keuntungan 100%'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) => _hitungHppDanHargaJual(),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Harga Jual Otomatis:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(currencyFormatter.format(_hargaJual), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _saveMenu, child: const Text('Simpan Menu'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildBahanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bahan yang Dibutuhkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
              onPressed: _showTambahBahanDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _daftarBahanPakai.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Belum ada bahan ditambahkan.', style: TextStyle(color: Colors.grey))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _daftarBahanPakai.length,
                itemBuilder: (context, index) {
                  final bahan = _daftarBahanPakai[index];
                  return Card(
                    child: ListTile(
                      title: Text(bahan.namaBahan),
                      subtitle: Text('${bahan.kuantitasPakai} ${bahan.satuanPakai}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _daftarBahanPakai.removeAt(index);
                            _hitungHppDanHargaJual();
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
