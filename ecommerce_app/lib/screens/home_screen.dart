import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:provider/provider.dart';

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
          .doc(_currentUser.uid)
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
        title: Text(_currentUser!= null ? 'Welcome, ${_currentUser.email}' : 'Home'),
        actions: [

          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. The "Badge" widget adds a small label
              return Badge(
                // 4. Get the count from the provider
                label: Text(cart.itemCount.toString()),
                // 5. Only show the badge if the count is > 0
                isLabelVisible: cart.itemCount > 0,
                // 6. This is the child (our icon button)
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 7. Navigate to the CartScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true) // 3. Show newest first
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }
          final products = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],

                onTap: () {
                  // 5. Navigate to the new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        // 6. Pass the data to the new screen
                        productData: productData,
                        productId: productDoc.id, // 7. Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}