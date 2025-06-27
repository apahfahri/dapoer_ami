// lib/widgets/detail_bahan_baku_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bahan_baku_model.dart';

// Widget ini fokus menampilkan detail dari satu objek BahanBaku.
class DetailBahanBakuContent extends StatelessWidget {
  final BahanBaku bahanBaku;

  const DetailBahanBakuContent({super.key, required this.bahanBaku});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final numberFormat = NumberFormat.decimalPattern('id_ID');

    // Menghitung harga per unit untuk ditampilkan
    final hargaPerUnit = bahanBaku.hargaPerUnit;
    final formattedHargaPerUnit = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 2
    ).format(hargaPerUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Judul
        Text(
          bahanBaku.nama,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),

        // Detail Pembelian
        _buildSectionTitle("Informasi Pembelian"),
        _detailRow("Harga Beli", currency.format(bahanBaku.hargaBeli)),
        _detailRow("Kuantitas Beli", '${numberFormat.format(bahanBaku.kuantitasBeli)} ${bahanBaku.satuanBeli}'),
        const Divider(height: 24),

        // Detail Harga Satuan
        _buildSectionTitle("Harga per Satuan"),
        _detailRow(
          "Harga per ${bahanBaku.satuanBeli}", 
          formattedHargaPerUnit, 
          isBold: true
        ),
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
