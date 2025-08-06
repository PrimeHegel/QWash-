import 'package:flutter/material.dart';
import 'package:qwash/screen/admin_data_screen.dart';
import 'package:qwash/screen/admin_screen.dart';
import 'package:qwash/screen/admin_profile_screen.dart';

class AdminNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const AdminNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF3F51B5),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      currentIndex: selectedIndex,
      onTap: (index) {
        // First handle the callback
        onItemTapped(index);

        // Then handle navigation based on the index
        if (selectedIndex != index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminDataScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminProfileScreen()),
              );
              break;
          }
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storage),
          label: 'Data',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
