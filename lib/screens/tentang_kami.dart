import 'package:flutter/material.dart';

class TentangKami extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Kami'),
        backgroundColor: const Color.fromARGB(255, 110, 255, 122),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Tentang Aplikasi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Aplikasi ini adalah aplikasi Kamus Besar Bahasa Indonesia (KBBI) yang membantu pengguna mencari arti kata dalam bahasa Indonesia.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Pengembang',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Bagas Luqman - 124220004',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Evanry Arkananta Ardine - 124220028',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}