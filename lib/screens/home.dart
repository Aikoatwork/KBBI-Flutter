import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'profil.dart';
import '../database/db_helper.dart';
import '../utils/kata_acak.dart';
import '../main.dart';
import 'tentang_kami.dart';

class Home extends StatefulWidget {
  final int userId;

  const Home({super.key, required this.userId});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  final List<dynamic> _words = [];
  bool _isLoading = false;

  // ignore: unused_field
  String? _profilePicturePath;

  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _requestNotificationPermissions();
    _scheduleDailyNotifications();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _dbHelper.getUserById(widget.userId);
      setState(() {
        _profilePicturePath = user?.profilePicture;
      });
    } catch (error) {
      print("Error loading profile picture: $error");
    }
  }

  Future<void> _searchWord(String query) async {
    if (query.isEmpty) {
      setState(() {
        _words.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('https://x-labs.my.id/api/kbbi/search/$query'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _words.clear();
            _words.addAll(data['data']);
          });
        } else {
          setState(() {
            _words.clear();
          });
        }
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      _showSnackBar('Error: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showRandomWordNotification() async {
    final String kataAcak = KataAcak.getKataAcak();
    final String apiUrl = 'https://x-labs.my.id/api/kbbi/search/$kataAcak';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'].isNotEmpty) {
          final wordData = data['data'][0];
          final String word = wordData['word'];
          final String description = wordData['arti'][0]['deskripsi'];

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 3,
              channelKey: 'daily_notification_channel',
              title: 'Kosakata Acak',
              body: 'Kata: $word, Arti: $description',
              notificationLayout: NotificationLayout.Default,
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _scheduleDailyNotifications() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'daily_notification_channel',
        title: 'Kosakata Acak',
        body: 'Klik untuk melihat kata acak hari ini!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 6,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'daily_notification_channel',
        title: 'Kosakata Acak',
        body: 'Klik untuk melihat kata acak sore ini!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 18,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KBBI'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari Kosakata...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    String query = _searchController.text;
                    _searchWord(query);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                    ? const Center(child: Text('Tidak ada hasil ditemukan'))
                    : ListView.builder(
                        itemCount: _words.length,
                        itemBuilder: (context, index) {
                          var word = _words[index];
                          return ListTile(
                            title: Text(word['word']),
                            subtitle: Text(word['arti'][0]['deskripsi']),
                            onTap: () {
                              _showSnackBar('Selected: ${word['word']}');
                            },
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showRandomWordNotification,
              child: const Text('Tampilkan Notifikasi Kata Acak'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<String?>(
              valueListenable: MyApp.profilePictureNotifier,
              builder: (context, profilePicture, child) {
                return CircleAvatar(
                  backgroundImage: profilePicture != null
                      ? FileImage(File(profilePicture))
                      : const NetworkImage(
                              'https://cdn-icons-png.flaticon.com/128/15501/15501313.png')
                          as ImageProvider,
                );
              },
            ),
            label: 'Profile',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Tentang Kami',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.userId),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TentangKami()),
            );
          }
        },
      ),
    );
  }
}
