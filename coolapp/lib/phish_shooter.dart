import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhishShooterPage extends StatefulWidget {
  const PhishShooterPage({super.key});

  @override
  State<PhishShooterPage> createState() => _PhishShooterPageState();
}

class _PhishShooterPageState extends State<PhishShooterPage> {
  // --- Game Settings ---
  double gameWidth = 0;
  double gameHeight = 0;
  bool gameHasStarted = false;
  int score = 0;
  int health = 5;
  Timer? gameLoopTimer;
  Timer? spawnTimer;

  // --- Visual Feedback & Leaderboard ---
  bool _isTakingDamage = false;
  bool isSavingScore = false; // Prevents spamming the database

  // --- Falling Objects Management ---
  List<FallingItem> items = [];
  double fallSpeed = 3.0;

  // --- CONTENT DATA ---
  final List<String> safeDomains = [
    "google.com", "maybank2u.com", "mygov.my", "shopee.com", "amazon.com"
  ];
  final List<String> phishDomains = [
    "g00gle.com", "maybank-security.net", "my-gov-login.xyz", "sh0pee-win.com", "amaz0n-verify.org"
  ];

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    spawnTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // --- HOW TO PLAY DIALOG ---
  // =========================================================================
  void _showHowToPlayDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.cyanAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "SYSTEM MANUAL",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  // Notice: The 'overflow' line is completely gone!
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Your mission is to protect the server from incoming traffic.", style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bug_report, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("TAP Red Links to destroy Phishing attempts before they reach the bottom.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mark_email_read, color: Colors.greenAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("IGNORE Green Links. Let legitimate traffic pass safely. If you tap them, you destroy important data!", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield, color: Colors.cyanAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("You have 5 Firewall Shields. Missing a red link or tapping a green link costs 1 shield.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("UNDERSTOOD", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void startGame() {
    setState(() {
      gameHasStarted = true;
      score = 0;
      health = 5;
      items.clear();
      fallSpeed = 3.0;
      _isTakingDamage = false;
    });

    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      updateGame();
    });

    spawnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      spawnItem();
    });
  }

  void spawnItem() {
    Random rand = Random();
    bool isPhishing = rand.nextBool();
    String text = isPhishing
        ? phishDomains[rand.nextInt(phishDomains.length)]
        : safeDomains[rand.nextInt(safeDomains.length)];

    double estimatedWidth = (text.length * 10.0) + 60.0;
    double maxValidX = (gameWidth - estimatedWidth).clamp(0.0, gameWidth);

    setState(() {
      items.add(FallingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + rand.nextInt(100).toString(),
        x: rand.nextDouble() * maxValidX,
        y: -80,
        text: text,
        isPhishing: isPhishing,
      ));
    });
  }

  void updateGame() {
    setState(() {
      double newSpeed = 3.0 + (score / 175.0);
      fallSpeed = newSpeed > 15.0 ? 15.0 : newSpeed;

      for (var item in items) {
        item.y += fallSpeed;
      }

      items.removeWhere((item) {
        if (item.y > gameHeight - 100) {
          if (item.isPhishing) {
            handleHealthLoss("Phishing breached firewall!");
          } else {
            score += 10; // Safe email delivered
          }
          return true;
        }
        return false;
      });
    });
  }

  void onTapItem(FallingItem item) {
    setState(() {
      if (item.isPhishing) {
        score += 50;
        HapticFeedback.lightImpact();
        items.remove(item);
      } else {
        handleHealthLoss("Deleted important business data!");
        items.remove(item);
      }
    });
  }

  void handleHealthLoss(String reason) {
    HapticFeedback.heavyImpact();

    setState(() {
      health--;
      _isTakingDamage = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isTakingDamage = false;
        });
      }
    });

    if (health <= 0) {
      gameOver();
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reason, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 800),
          )
      );
    }
  }

  // =========================================================================
  // --- LEADERBOARD LOGIC: SAVING AND FETCHING HIGH SCORES ---
  // =========================================================================
  Future<void> gameOver() async {
    gameLoopTimer?.cancel();
    spawnTimer?.cancel();

    setState(() {
      isSavingScore = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        // 1. Fetch the user's real username
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final username = userDoc.data()?['username'] ?? "Anonymous Agent";

        // 2. Save the score to the Global "Phish Shooter" Leaderboard
        final leaderboardRef = FirebaseFirestore.instance
            .collection('leaderboards')
            .doc('Phish Shooter')
            .collection('scores')
            .doc(uid);

        final currentScoreDoc = await leaderboardRef.get();
        int previousScore = currentScoreDoc.data()?['score'] ?? 0;

        // ONLY save if their new score is higher than their old score!
        if (score > previousScore) {
          await leaderboardRef.set({
            'username': username,
            'score': score,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("Error saving score: $e");
      }
    }

    if (mounted) {
      setState(() => isSavingScore = false);
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Column(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 50),
            SizedBox(height: 10),
            Text("SYSTEM FAILURE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Your firewall was breached.\nFinal Score: $score XP", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 20),

              // --- THE LEADERBOARD UI ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("TOP 5 FIREWALL ADMINS", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),

              // Real-time fetch of the top 5 scores!
              SizedBox(
                height: 180,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('leaderboards')
                      .doc('Phish Shooter')
                      .collection('scores')
                      .orderBy('score', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No high scores yet. Be the first!", style: TextStyle(color: Colors.grey)));
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("#${index + 1} ${data['username']}", style: TextStyle(color: index == 0 ? Colors.amber : Colors.white70, fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal)),
                              Text("${data['score']} XP", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to home
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            child: const Text("EXIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                gameHasStarted = false; // Reset to start screen
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("REBOOT SYSTEM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    gameWidth = MediaQuery.of(context).size.width;
    gameHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("PHISH ZAPPER", style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.blueGrey, fontWeight: FontWeight.w900)),
            Text("$score XP", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Courier')),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. The Game Area
          ...items.map((item) {
            return Positioned(
              top: item.y,
              left: item.x,
              child: Listener(
                onPointerDown: (_) => onTapItem(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.isPhishing ? Colors.redAccent : Colors.greenAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: item.isPhishing ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          item.isPhishing ? Icons.bug_report : Icons.mark_email_read,
                          color: item.isPhishing ? Colors.redAccent : Colors.greenAccent,
                          size: 20
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 2. Health Bar
          Positioned(
            bottom: 30,
            left: 20,
            child: Row(
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.shield,
                    color: index < health ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
                    size: 28,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 35,
            right: 20,
            child: Text("FIREWALL INTEGRITY", style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),

          // 3. DAMAGE FLASH OVERLAY
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: _isTakingDamage ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 4. Start Button Overlay / Saving Indicator
          if (!gameHasStarted)
            Container(
              color: const Color(0xFF0D1117).withValues(alpha: 0.95),
              child: Center(
                child: isSavingScore
                    ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 16),
                    Text("Uploading Score to Global Network...", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ],
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent, width: 2)
                      ),
                      child: const Icon(Icons.admin_panel_settings, size: 60, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 24),
                    const Text("INCOMING TRAFFIC", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Text("🚨 TAP Red Links (Phishing)", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Text("✅ IGNORE Green Links (Safe)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: startGame,
                      child: const Text("START FIREWALL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 20),
                    // --- THE NEW HOW TO PLAY BUTTON ---
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.help_outline, size: 20),
                      label: const Text("HOW TO PLAY"),
                      onPressed: _showHowToPlayDialog,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Helper Class ---
class FallingItem {
  String id;
  double x;
  double y;
  String text;
  bool isPhishing;

  FallingItem({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.isPhishing,
  });
}