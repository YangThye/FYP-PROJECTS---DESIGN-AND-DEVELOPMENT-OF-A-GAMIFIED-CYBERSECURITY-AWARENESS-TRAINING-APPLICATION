import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'deepfake_game.dart';
import 'package:coolapp/phish_shooter.dart'; // Adjust import if needed
import 'quiz_page.dart';
import 'job_hunter.dart';
import 'leaderboard_page.dart'; // <-- NEW IMPORT!

class GameHomePage extends StatelessWidget {
  const GameHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {

              bool isPhishingUnlocked = false;
              bool isDeepfakeUnlocked = false;
              bool isJobScamUnlocked = false;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final unlockedMap = data['unlocked_videos'] as Map<String, dynamic>? ?? {};

                isPhishingUnlocked = unlockedMap['Phishing'] == true;
                isDeepfakeUnlocked = unlockedMap['Deepfakes'] == true;
                isJobScamUnlocked = unlockedMap['Job Scams'] == true;
              }

              return ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                children: [
                  // --- HEADER ---
                  const Text(
                    "Cyber Arcade",
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a mission to test your skills.",
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // --- NEW: HALL OF FAME BUTTON ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Shiny Gold Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("GLOBAL HALL OF FAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
                                Text("Check the top ranked players", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- SECTION 1: MINI-GAMES ---
                  const Text("Interactive Mini-Games", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Job Hunter",
                    subtitle: "Spot the fake recruiter before it's too late!",
                    icon: Icons.person_search,
                    color: Colors.teal,
                    targetPage: const JobHunterPage(),
                  ),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Phish Shooter",
                    subtitle: "Blast away malicious phishing emails.",
                    icon: Icons.security,
                    color: Colors.blue,
                    targetPage: const PhishShooterPage(),
                  ),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Glitch Hunter",
                    subtitle: "Spot AI-generated glitches before time runs out.",
                    icon: Icons.face_retouching_off,
                    color: Colors.purple,
                    targetPage: const DeepfakeGamePage(),
                  ),
                  const SizedBox(height: 32), // Adjusted padding to transition smoothly to next section

                  // --- SECTION 2: KNOWLEDGE ASSESSMENTS ---
                  const Text("Knowledge Assessments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Job Scams Assessment",
                    subtitle: "50 Questions available • Learn the red flags of fake recruitment.",
                    icon: Icons.work_off,
                    color: Colors.redAccent,
                    targetPage: const QuizPage(
                        chapterName: "Job Scams Assessment",
                        isArcadeMode: true,
                    ),
                    isLocked: !isJobScamUnlocked,
                    lockMessage: "Watch the 'Job Scams' video module to unlock this assessment.",
                  ),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Phishing Assessment",
                    subtitle: "50 Questions available • Identify typosquatting and fake URLs.",
                    icon: Icons.phishing,
                    color: Colors.orange,
                    targetPage: const QuizPage(
                        chapterName: "Phishing Assessment",
                        isArcadeMode: true,
                    ),
                    isLocked: !isPhishingUnlocked,
                    lockMessage: "Watch the 'Phishing' video module to unlock this assessment.",
                  ),
                  const SizedBox(height: 16),

                  _buildGameCard(
                    context: context,
                    title: "Deepfake Assessment",
                    subtitle: "50 Questions available • Spot AI-generated glitches and audio flaws.",
                    icon: Icons.face_retouching_off,
                    color: Colors.purple,
                    targetPage: const QuizPage(
                        chapterName: "Deepfake Assessment",
                        isArcadeMode: true,
                    ),
                    isLocked: !isDeepfakeUnlocked,
                    lockMessage: "Watch the 'Deepfakes' video module to unlock this assessment.",
                  ),
                  const SizedBox(height: 32),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget targetPage,
    bool isLocked = false,
    String lockMessage = "This module is locked.",
  }) {
    final displayColor = isLocked ? Colors.grey.shade400 : color;
    final displayIcon = isLocked ? Icons.lock_outline : icon;
    final trailingIcon = isLocked ? Icons.lock : Icons.play_arrow;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lockMessage),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isLocked)
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: displayColor.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(color: displayColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(displayIcon, size: 32, color: displayColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey.shade500 : Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? "Locked Assessment" : subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isLocked ? Colors.grey.shade200 : color, shape: BoxShape.circle),
              child: Icon(trailingIcon, color: isLocked ? Colors.grey.shade500 : Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}