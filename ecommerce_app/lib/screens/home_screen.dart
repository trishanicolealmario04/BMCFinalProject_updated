import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/screens/admin_panel_screen.dart'; // 2. ADD THIS


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. Use the _currentUser variable we defined
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser!.email}' : 'Home'),
        actions: [

          // 2. --- THIS IS THE MAGIC ---
          //    This is a "collection-if". The IconButton will only
          //    be built IF _userRole is equal to 'admin'.
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                // 3. This is why we imported admin_panel_screen.dart
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 4. The logout button (always visible)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut, // 5. Call our _signOut function
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'This is the Home Screen. Products will be listed here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
