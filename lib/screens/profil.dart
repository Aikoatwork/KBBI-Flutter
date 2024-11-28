import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import 'login.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DBHelper _dbHelper = DBHelper();
  late User _user;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
    _loadUserData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _dbHelper.getUserById(widget.userId);
      if (user != null) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('No user data found', Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to load user data: $error', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _pickAndSaveImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(pickedFile.path).copy('$path/$fileName');

        await _dbHelper.updateUserProfilePicture(widget.userId, savedImage.path);

        setState(() {
          _user = User(
            id: _user.id,
            username: _user.username,
            password: _user.password,
            profilePicture: savedImage.path,
          );
        });

        MyApp.profilePictureNotifier.value = savedImage.path;

        _showSnackBar('Profile picture updated!', Colors.green);
        print('Profile Picture Path: ${_user.profilePicture}');
      }
    } catch (error) {
      _showSnackBar('Failed to upload image: $error', Colors.red);
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now();
    });
  }

  String _formatTime(DateTime time) {
    final format = DateFormat('EEEE, HH:mm:ss');
    return format.format(time);
  }

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(text: _user.username);
    final passwordController = TextEditingController(text: _user.password);
    String? newProfilePicture = _user.profilePicture;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 20),
                    newProfilePicture != null
                        ? SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.file(File(newProfilePicture!)),
                          )
                        : const Text('No image selected'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final path = directory.path;
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                          final savedImage = await File(pickedFile.path).copy('$path/$fileName');
                          setState(() {
                            newProfilePicture = savedImage.path;
                          });
                        }
                      },
                      child: const Text('Ganti Foto Profil'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          newProfilePicture = null;
                        });
                      },
                      child: const Text('Hapus Foto Profil'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    final newUsername = usernameController.text;
                    final newPassword = passwordController.text;

                    final updatedUser = User(
                      id: _user.id,
                      username: newUsername,
                      password: newPassword,
                      profilePicture: newProfilePicture,
                    );

                    await _dbHelper.insertUser(updatedUser);

                    setState(() {
                      _user = updatedUser;
                    });

                    MyApp.profilePictureNotifier.value = newProfilePicture;

                    Navigator.pop(context);
                    _showSnackBar('Profil Berhasil Diperbarui!', Colors.green);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'),
      backgroundColor: const Color.fromARGB(255, 110, 255, 122),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _user.username.isEmpty
                ? const Text('No user data found')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _user.profilePicture != null
                            ? FileImage(File(_user.profilePicture!))
                            : const NetworkImage(
                                'https://cdn-icons-png.flaticon.com/128/15501/15501313.png',
                              ) as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Username: ${_user.username}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showEditProfileDialog,
                        child: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _logout,
                        child: const Text('Log Out'),
                      ),
                      const SizedBox(height: 20),
                      Text('Current Time: ${_formatTime(_currentTime)}'),
                    ],
                  ),
      ),
    );
  }
}