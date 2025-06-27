import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import file yang dihasilkan oleh FlutterFire CLI.
// Pastikan Anda sudah menjalankan 'flutterfire configure'.
import 'utils/firebase_options.dart';

// Import halaman-halaman yang sudah kita buat.
import 'package:dapoer_ami/pages/LoginPage.dart';
import 'package:dapoer_ami/pages/HomePage.dart';

// Fungsi main() adalah gerbang utama aplikasi.
// Dibuat 'async' karena kita perlu menunggu Firebase selesai diinisialisasi.
void main() async {
  // Memastikan semua binding widget Flutter sudah siap sebelum menjalankan kode native.
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase menggunakan konfigurasi platform saat ini.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Menjalankan aplikasi.
  // runApp(const MyApp());
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => const MyApp(),
  ));
}

// MyApp adalah widget root dari aplikasi Anda.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nonaktifkan banner debug di pojok kanan atas.
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Catering',
      theme: ThemeData(
        // Menggunakan skema warna berbasis Material 3 dari warna utama.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        // Atur tema untuk AppBar agar konsisten di seluruh aplikasi.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      // 'home' akan diisi oleh AuthWrapper yang menentukan halaman awal.
      home: const AuthWrapper(),
    );
  }
}

// AuthWrapper adalah widget cerdas untuk menangani alur otentikasi.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder secara konstan mendengarkan perubahan status otentikasi dari Firebase.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Saat sedang menunggu koneksi atau data pertama.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Jika terjadi error pada stream.
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Terjadi kesalahan. Silakan mulai ulang aplikasi.'),
            ),
          );
        }

        // 3. Jika snapshot memiliki data (artinya, objek User tidak null),
        //    maka pengguna sudah login.
        if (snapshot.hasData) {
          return const HomePage(); // Arahkan ke Halaman Utama.
        }

        // 4. Jika snapshot tidak memiliki data (objek User adalah null),
        //    maka pengguna belum login.
        else {
          return const LoginPage(); // Arahkan ke Halaman Login.
        }
      },
    );
  }
}
