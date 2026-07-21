import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeepfakeGamePage extends StatefulWidget {
  const DeepfakeGamePage({super.key});

  @override
  State<DeepfakeGamePage> createState() => _DeepfakeGamePageState();
}

class _DeepfakeGamePageState extends State<DeepfakeGamePage> {
  int _currentLevel = 0;
  int _score = 0;
  int _timeLeft = 15;
  Timer? _timer;

  bool gameHasStarted = false; // <-- NEW: Start Screen State
  bool _isGameOver = false;
  bool _isSavingScore = false;

  // --- THE REAL LEVELS ---
  final List<Map<String, dynamic>> _levels = [
    {
      "title": "Level 1: The Extra Finger",
      "instruction": "Scan the image. Tap the AI-generated hand anomaly.",
      "imagePath": "assets/images/df_level1.png",
      "targetX": 0.77,
      "targetY": 0.57,
      "successMessage": "Good eye! AI generators frequently add extra fingers or blend them together.",
    },
    {
      "title": "Level 2: The Warped Wall",
      "instruction": "Find the spatial glitch in the background.",
      "imagePath": "assets/images/df_level2.png",
      "targetX": 0.17,
      "targetY": 0.68,
      "successMessage": "Spot on! Background lines (like walls or fences) often warp or bend unnaturally around AI faces.",
    },
    {
      "title": "Level 3: The Blurry Jawline",
      "instruction": "Tap the blurry, pixelated patch on the lower right side of his jaw.",
      "imagePath": "assets/images/df_level3.png",
      "targetX": 0.6,
      "targetY": 0.7,
      "successMessage": "Perfect! Deepfake masks often blur or tear at the edges of the jaw and neck.",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Do NOT start timer here; wait for the player to click START.
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
            side: const BorderSide(color: Colors.greenAccent, width: 2),
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
              Text("Your mission is to detect AI-generated anomalies in the images provided.", style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.image_search, color: Colors.greenAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("SCAN the image carefully based on the instructions at the top.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, color: Colors.cyanAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("TAP directly on the glitch or anomaly when you spot it.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.timer, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("Be fast! Faster detection equals higher XP. Tapping the wrong spot deducts 3 seconds from your timer.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
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
      _currentLevel = 0;
      _score = 0;
      _isGameOver = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    setState(() {
      _isGameOver = true;
      _isSavingScore = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final username = userDoc.data()?['username'] ?? "Anonymous Agent";

        final leaderboardRef = FirebaseFirestore.instance
            .collection('leaderboards')
            .doc('Glitch Hunter')
            .collection('scores')
            .doc(uid);

        final currentScoreDoc = await leaderboardRef.get();
        int previousScore = currentScoreDoc.data()?['score'] ?? 0;

        if (_score > previousScore) {
          await leaderboardRef.set({
            'username': username,
            'score': _score,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("Error saving score: $e");
      }
    }

    if (mounted) {
      setState(() => _isSavingScore = false);
    }
  }

  void _onTargetTapped() {
    _timer?.cancel();

    int timeTaken = 15 - _timeLeft;
    int pointsEarned = 1000 - (timeTaken * 50);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.greenAccent, width: 2)
          ),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text("Glitch Found!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_levels[_currentLevel]["successMessage"], style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 15),
              Text("Time Taken: $timeTaken seconds", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("Points Earned: +$pointsEarned XP", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_currentLevel < _levels.length - 1) {
                  setState(() {
                    _currentLevel++;
                    _score += pointsEarned;
                  });
                  _startTimer();
                } else {
                  setState(() {
                    _score += pointsEarned;
                  });
                  _endGame();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              child: const Text("Next Subject", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        )
    );
  }

  void _onMissTapped() {
    setState(() {
      if (_timeLeft > 3) {
        _timeLeft -= 3;
      } else {
        _timeLeft = 0;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("MISS! Signal Traced. -3 Seconds.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 50, right: 50),
        )
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameOver) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: _isSavingScore
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.greenAccent),
              SizedBox(height: 16),
              Text("Uploading Score to Global Network...", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text("ANALYSIS COMPLETE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text("Final Score: $_score XP", style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 30),

              // THE LEADERBOARD BOX
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 2)
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text("TOP 5 GLITCH HUNTERS", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 180,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('leaderboards')
                            .doc('Glitch Hunter')
                            .collection('scores')
                            .orderBy('score', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
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
                                    Text("${data['score']} XP", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Return to Arcade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      );
    }

    final levelData = _levels[_currentLevel];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Score: $_score", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN GAMEPLAY AREA ---
            Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          levelData["title"],
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: _timeLeft <= 5 ? Colors.red.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _timeLeft <= 5 ? Colors.red : Colors.grey.withValues(alpha: 0.5))
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, color: _timeLeft <= 5 ? Colors.redAccent : Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text("00:${_timeLeft.toString().padLeft(2, '0')}",
                                style: TextStyle(color: _timeLeft <= 5 ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(levelData["instruction"], style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ),
                const SizedBox(height: 30),

                // THE IMAGE AREA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)
                                ],
                                border: Border.all(color: Colors.white24, width: 2)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    levelData["imagePath"],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                          const SizedBox(height: 10),
                                          Text("Missing Image:\n${levelData["imagePath"]}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                                        ],
                                      );
                                    },
                                  ),

                                  if (gameHasStarted) ...[
                                    GestureDetector(
                                      onTap: _onMissTapped,
                                      child: Container(
                                        color: Colors.transparent,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      left: constraints.maxWidth * levelData["targetX"] - 35,
                                      top: constraints.maxHeight * levelData["targetY"] - 35,
                                      child: GestureDetector(
                                        onTap: _onTargetTapped,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent)),
              ],
            ),

            // --- START SCREEN OVERLAY ---
            if (!gameHasStarted)
              Container(
                color: const Color(0xFF0D1117).withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.greenAccent, width: 2)
                        ),
                        child: const Icon(Icons.face_retouching_off, size: 60, color: Colors.greenAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text("GLITCH HUNTER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          children: [
                            Text("👁️ Scan the image carefully", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text("🎯 Tap the AI anomaly to score", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: startGame,
                        child: const Text("START SCAN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 20),
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
      ),
    );
  }
}