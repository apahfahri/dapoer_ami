// lib/widgets/detail_menu_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';

// Widget ini fokus menampilkan detail dari satu objek Menu.
class DetailMenuContent extends StatelessWidget {
  final Menu menu;

  const DetailMenuContent({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final numberFormat = NumberFormat.decimalPattern('id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bagian Informasi Umum
        Text(
          menu.namaMenu,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (menu.deskripsi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
            child: Text(menu.deskripsi, style: const TextStyle(color: Colors.grey)),
          ),
        const Divider(height: 24),

        // Bagian Kalkulasi Harga
        _buildSectionTitle("Kalkulasi Harga"),
        _detailRow("Harga Pokok (HPP)", currency.format(menu.hpp)),
        _detailRow("Markup Keuntungan", '${numberFormat.format(menu.markup)}%'),
        _detailRow("Harga Jual Final", currency.format(menu.harga), isBold: true),
        const Divider(height: 24),

        // Bagian Daftar Bahan
        _buildSectionTitle("Resep Bahan per Porsi"),
        if (menu.bahan.isEmpty)
          const Text('Tidak ada data bahan untuk menu ini.', style: TextStyle(fontStyle: FontStyle.italic))
        else
          ...menu.bahan.map((bahan) {
            final formattedKuantitas = bahan.kuantitasPakai.toStringAsFixed(2).replaceAll(RegExp(r'([.,]00)$'), '');
            return _detailRow(
              '- ${bahan.namaBahan}',
              '$formattedKuantitas ${bahan.satuanPakai}',
            );
          }).toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black87 : Colors.grey[700])),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
