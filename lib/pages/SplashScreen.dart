import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _GoToNavigationToHome();
  }

  _GoToNavigationToHome() async {
    await Future.delayed(const Duration(seconds: 5));
    Navigator.pushReplacementNamed(context, 'home_screen');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/images/logo omah.png'),
              width: 300,
              height: 300,
            ),
            Text(
              'OMAH',
              style: TextStyle(
                fontSize: 40,
              ),
            )
          ],
        ),
      ),
    );
  }
}
