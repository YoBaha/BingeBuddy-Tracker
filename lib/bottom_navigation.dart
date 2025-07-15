import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:bingebuddy/screens/landing_screen.dart';
import 'package:bingebuddy/screens/home_screen.dart';
import 'package:bingebuddy/screens/watchlist_screen.dart';
import 'package:bingebuddy/screens/profile_screen.dart';
import 'package:bingebuddy/screens/watched_screen.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  // Public method to navigate to a specific index
  void navigateTo(int index, BuildContext context) {
    final state = context.findAncestorStateOfType<_BottomNavigationState>();
    if (state != null) {
      state.setState(() {
        state.selected = index;
        state._selectedIndexNotifier.value = index;
        state.controller.jumpToPage(index);
      });
    }
  }

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int selected = 0;
  final PageController controller = PageController(initialPage: 0); // Start on HomeScreen
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0); // Sync with initial page

  @override
  void initState() {
    super.initState();
    print('BottomNavBar initialized');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      print('No user found, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
    _selectedIndexNotifier.addListener(() {
      if (selected != _selectedIndexNotifier.value) {
        setState(() {
          selected = _selectedIndexNotifier.value;
          controller.jumpToPage(selected);
        });
      }
    });
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building BottomNavBar, selected index: $selected');
    final authProvider = Provider.of<AuthProvider>(context);

    return Material(
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: controller,
          children: const [
            LandingScreen(),
            HomeScreen(),
            WatchlistScreen(),
            WatchedScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (index) {
            print('Page changed to index: $index');
            setState(() {
              selected = index;
              _selectedIndexNotifier.value = index;
            });
          },
        ),
        bottomNavigationBar: StylishBottomBar(
          option: AnimatedBarOptions(
            iconStyle: IconStyle.animated,
            barAnimation: BarAnimation.liquid,
            opacity: 0.3,
          ),
          items: [
            BottomBarItem(
              icon: const Icon(Icons.home, color: Color(0xFFEAEAEA)),
              title: const Text(
                'Landing',
                style: TextStyle(color: Color(0xFFEAEAEA), decoration: TextDecoration.none),
              ),
              backgroundColor: const Color(0xFF1F1D2B),
              selectedColor: Color(0xFF12CDC9),
              selectedIcon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12CDC9), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ),
            BottomBarItem(
              icon: const Icon(Icons.movie, color: Color(0xFFEAEAEA)),
              title: const Text(
                'Home',
                style: TextStyle(color: Color(0xFFEAEAEA), decoration: TextDecoration.none),
              ),
              backgroundColor: const Color(0xFF1F1D2B),
              selectedColor: Color(0xFF12CDC9),
              selectedIcon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12CDC9), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.movie, color: Colors.white),
              ),
            ),
            BottomBarItem(
              icon: const Icon(Icons.list, color: Color(0xFFEAEAEA)),
              title: const Text(
                'Watchlist',
                style: TextStyle(color: Color(0xFFEAEAEA), decoration: TextDecoration.none),
              ),
              backgroundColor: const Color(0xFF1F1D2B),
              selectedColor: Color(0xFF12CDC9),
              selectedIcon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12CDC9), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.list, color: Colors.white),
              ),
            ),
            BottomBarItem(
              icon: const Icon(Icons.check_circle, color: Color(0xFFEAEAEA)),
              title: const Text(
                'Watched',
                style: TextStyle(color: Color(0xFFEAEAEA), decoration: TextDecoration.none),
              ),
              backgroundColor: const Color(0xFF1F1D2B),
              selectedColor: Color(0xFF12CDC9),
              selectedIcon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12CDC9), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.white),
              ),
            ),
            BottomBarItem(
              icon: const Icon(Icons.person, color: Color(0xFFEAEAEA)),
              title: const Text(
                'Profile',
                style: TextStyle(color: Color(0xFFEAEAEA), decoration: TextDecoration.none),
              ),
              backgroundColor: const Color(0xFF1F1D2B),
              selectedColor: Color(0xFF12CDC9),
              selectedIcon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12CDC9), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
          currentIndex: selected,
          onTap: (index) {
            print('Nav bar item tapped: $index');
            setState(() {
              selected = index;
              _selectedIndexNotifier.value = index;
              controller.jumpToPage(index);
            });
          },
          backgroundColor: const Color(0xFF1F1D2B),
          elevation: 8,
        ),
      ),
    );
  }
}