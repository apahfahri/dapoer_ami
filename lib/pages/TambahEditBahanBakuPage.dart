// lib/pages/tambah_edit_bahan_baku_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bahan_baku_model.dart';

class TambahEditBahanBakuPage extends StatefulWidget {
  final BahanBaku? bahanBaku;

  const TambahEditBahanBakuPage({super.key, this.bahanBaku});

  @override
  State<TambahEditBahanBakuPage> createState() => _TambahEditBahanBakuPageState();
}

class _TambahEditBahanBakuPageState extends State<TambahEditBahanBakuPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _kuantitasBeliController = TextEditingController();
  
  // --- PERUBAHAN 1: Hapus _satuanBeliController dan ganti dengan ini ---
  String? _selectedSatuan; // Variabel untuk menyimpan nilai dropdown yang dipilih

  // Daftar opsi satuan yang akan ditampilkan di dropdown
  final List<String> _satuanOptions = [
    'kg', 'gram', 'liter', 'ml', 'butir', 'buah', 'pcs', 'ikat', 'sdm', 'sdt'
  ];

  bool _isLoading = false;
  late String _appBarTitle;

  @override
  void initState() {
    super.initState();

    if (widget.bahanBaku != null) {
      _appBarTitle = 'Edit Bahan Baku';
      _namaController.text = widget.bahanBaku!.nama;
      _hargaBeliController.text = widget.bahanBaku!.hargaBeli.toString();
      _kuantitasBeliController.text = widget.bahanBaku!.kuantitasBeli.toString();
      
      // --- PERUBAHAN 2: Set nilai awal untuk dropdown ---
      // Pastikan nilai yang ada di database juga ada di _satuanOptions
      if (_satuanOptions.contains(widget.bahanBaku!.satuanBeli)) {
        _selectedSatuan = widget.bahanBaku!.satuanBeli;
      }
    } else {
      _appBarTitle = 'Tambah Bahan Baku';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaBeliController.dispose();
    _kuantitasBeliController.dispose();
    // Tidak perlu dispose _satuanBeliController lagi
    super.dispose();
  }

  Future<void> _saveBahanBaku() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final data = {
        'nama': _namaController.text,
        'hargaBeli': double.tryParse(_hargaBeliController.text) ?? 0,
        'kuantitasBeli': double.tryParse(_kuantitasBeliController.text) ?? 0,
        // --- PERUBAHAN 3: Ambil nilai dari state dropdown, bukan controller ---
        'satuanBeli': _selectedSatuan,
      };

      if (widget.bahanBaku != null) {
        await FirebaseFirestore.instance.collection('bahan_baku').doc(widget.bahanBaku!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('bahan_baku').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bahan baku berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Bahan Baku', hintText: 'Contoh: Daging Ayam'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaBeliController,
                decoration: const InputDecoration(labelText: 'Harga Beli (Rp)', prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value!.isEmpty ? 'Harga tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kuantitasBeliController,
                decoration: const InputDecoration(labelText: 'Kuantitas Pembelian', hintText: 'Contoh: 1 atau 10'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Kuantitas tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              // --- PERUBAHAN 4: Ganti TextFormField dengan DropdownButtonFormField ---
              DropdownButtonFormField<String>(
                value: _selectedSatuan,
                decoration: const InputDecoration(
                  labelText: 'Satuan Pembelian',
                  border: OutlineInputBorder(), // Memberi border agar terlihat seperti form lain
                ),
                hint: const Text('Pilih satuan'),
                isExpanded: true,
                items: _satuanOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSatuan = newValue;
                  });
                },
                validator: (value) => value == null ? 'Satuan harus dipilih' : null,
              ),

              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveBahanBaku,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Simpan Bahan Baku'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
