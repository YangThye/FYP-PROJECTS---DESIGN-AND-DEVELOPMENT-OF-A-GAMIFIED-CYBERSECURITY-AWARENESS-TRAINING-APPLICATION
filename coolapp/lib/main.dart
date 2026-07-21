import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'game_home_page.dart';
import 'home_page.dart';
import 'learning_page.dart';
import 'account_page.dart';
import 'login_page.dart';
import 'preliminary_check_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CyberShield Quiz',

      // --- THE FIX: STRICTLY DEFINED APP THEME ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Globally sets your custom background
        colorScheme: const ColorScheme.light(
          primary: Colors.blueAccent,     // Forces main interactions to be blue
          secondary: Colors.blueAccent,   // Eradicates the default Material 3 purple!
          surface: Colors.white,          // Keeps cards, dialogs, and dropdowns clean white
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),

      home: const AuthGate(),
    );
  }
}

// --- THE SMART ROUTER ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen to Firebase to see if they are logged in
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFFF5F7FA), body: Center(child: CircularProgressIndicator()));
        }

        // 2. If NO user is found, send them to Login
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginPage();
        }

        // 3. If a user IS found, check their database profile!
        final uid = authSnapshot.data!.uid;
        final userEmail = authSnapshot.data!.email ?? "Agent";

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Color(0xFFF5F7FA), body: Center(child: CircularProgressIndicator()));
            }

            // 4. Check the onboarding flag
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              if (data['onboarding_complete'] == true) {
                // Fully verified agent -> Send to Dashboard!
                return MyHomePage(username: userEmail);
              }
            }

            // 5. Logged in, but hasn't finished onboarding -> Send to Init screen!
            return const PreliminaryCheckPage();
          },
        );
      },
    );
  }
}

// --- BEAUTIFUL NAV BAR ---
class MyHomePage extends StatefulWidget {
  final String username;
  const MyHomePage({super.key, required this.username});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(username: widget.username),
      const LearningPage(),
      const GameHomePage(),
      const AccountPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F7FA),
      body: _pages[_selectedIndex],

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 70,
                color: Colors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(icon: Icons.home_filled, label: "Home", index: 0),
                    _buildNavItem(icon: Icons.book_rounded, label: "Learning", index: 1),
                    _buildNavItem(icon: Icons.grid_view_rounded, label: "Games", index: 2),
                    _buildNavItem(icon: Icons.person_rounded, label: "Account", index: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.redAccent : Colors.black54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.redAccent : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}