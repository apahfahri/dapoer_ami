// lib/services/pdf_invoice_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pesanan_model.dart';

class PdfInvoiceService {
  final Pesanan pesanan;

  PdfInvoiceService({required this.pesanan});

  /// Membuat nama file yang dinamis berdasarkan nama pelanggan dan tanggal.
  /// Contoh: 'Struk-DapoerAmi-Andi-Sun-28-Jun-2025.pdf'
  String generateFileName() {
    final name = pesanan.namaPelanggan.replaceAll(' ', '-');
    final date = DateFormat('E-dd-MMM-yyyy', 'id_ID').format(pesanan.tanggalPesan);
    return 'Struk-DapoerAmi-$name-$date.pdf';
  }

  // Fungsi diubah menjadi async untuk bisa memuat data font dari assets
  Future<Uint8List> createInvoice() async {
    final pdf = pw.Document();

    // 1. Memuat font yang mendukung Unicode (PENTING untuk mengatasi error)
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    // 2. Membuat style dasar yang akan digunakan di seluruh dokumen
    final baseStyle = pw.TextStyle(font: ttf, fontSize: 9);
    final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 9);

    pdf.addPage(
      pw.Page(
        // 3. Mengatur ukuran halaman sesuai struk thermal 80mm
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8), // Mengatur margin agar tidak terlalu mepet
        build: (pw.Context context) {
          // Mengirim style ke fungsi build agar digunakan secara konsisten
          return _buildContent(context, baseStyle, boldStyle);
        },
      ),
    );

    return pdf.save();
  }

  // Semua widget sekarang menerima style sebagai parameter
  pw.Widget _buildContent(pw.Context context, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(context, baseStyle, boldStyle),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
        _buildCustomerInfo(dateFormatter, baseStyle, boldStyle),
        pw.SizedBox(height: 12),
        _buildItemsTable(currency, baseStyle, boldStyle),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 5),
        _buildPaymentSummary(currency, baseStyle, boldStyle),
        pw.SizedBox(height: 20),
        _buildFooter(context, baseStyle),
      ],
    );
  }

  pw.Widget _buildHeader(pw.Context context, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text('DAPOER AMI CATERING', style: boldStyle.copyWith(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text('Belakang Mall Paris Van Java, Bandung', style: baseStyle, textAlign: pw.TextAlign.center),
          pw.Text('Telp: 0812-XXXX-XXXX', style: baseStyle, textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          pw.Text('STRUK PEMBELIAN', style: boldStyle),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(DateFormat dateFormatter, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Column(
      children: [
        _infoRow('No. Pesanan:', pesanan.id.substring(0, 8).toUpperCase(), baseStyle, boldStyle),
        _infoRow('Pelanggan:', pesanan.namaPelanggan, baseStyle, boldStyle),
        _infoRow('Tgl. Pesan:', dateFormatter.format(pesanan.tanggalPesan), baseStyle, boldStyle),
        _infoRow('Tgl. Kirim:', dateFormatter.format(pesanan.tanggalKirim), baseStyle, boldStyle),
      ],
    );
  }
  
  pw.Widget _buildItemsTable(NumberFormat currency, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    final headers = ['Item', 'qty', 'Harga', 'Total'];
    final data = pesanan.items.map((item) {
      return [
        item.namaMenu,
        item.jumlah.toString(),
        currency.format(item.harga),
        currency.format(item.harga * item.jumlah),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: boldStyle,
      cellStyle: baseStyle,
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2.5),
      },
    );
  }

  pw.Widget _buildPaymentSummary(NumberFormat currency, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _summaryRow('Subtotal', currency.format(pesanan.subTotal), baseStyle, boldStyle),
        _summaryRow('Diskon', currency.format(pesanan.diskon), baseStyle, boldStyle),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
        _summaryRow('Grand Total', currency.format(pesanan.grandTotal), baseStyle, boldStyle, isTotal: true),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.TextStyle baseStyle) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Text('Terima Kasih Telah Memesan!', style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 5),
          pw.Text('Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}', style: baseStyle.copyWith(fontSize: 7, color: PdfColors.grey700)),
        ],
      ),
    );
  }
  
  pw.Widget _infoRow(String label, String value, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: boldStyle),
          pw.Text(value, style: baseStyle),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, pw.TextStyle baseStyle, pw.TextStyle boldStyle, {bool isTotal = false}) {
    final style = isTotal ? boldStyle.copyWith(fontSize: 10) : baseStyle;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
