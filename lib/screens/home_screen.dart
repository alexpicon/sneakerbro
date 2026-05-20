import 'package:flutter/material.dart';

import '../theme.dart';
import 'catalog_screen.dart';
import 'collection_screen.dart';
import 'dashboard_screen.dart';
import 'drop_alerts_screen.dart';
import 'wishlist_screen.dart';

/// The app shell: a five-tab bottom navigation bar. The analytics, add/edit
/// and sneaker-detail screens are pushed on top of these tabs as needed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const List<Widget> _tabs = [
    DashboardScreen(),
    CollectionScreen(),
    WishlistScreen(),
    CatalogScreen(),
    DropAlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's scroll position and state alive while
      // the user moves between tabs.
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBrandColor,
        unselectedItemColor: const Color(0xFF9A9AA2),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
