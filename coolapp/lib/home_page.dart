import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'video_player_page.dart';
import 'quiz_page.dart';

class HomePage extends StatelessWidget {
  final String username;

  const HomePage({super.key, required this.username});

  // --- SMART DAILY TIP LOGIC ---
  String _getDailyTip() {
    final List<String> tips = [
      "Public Wi-Fi is like a public conversation. Avoid checking your bank balance on it!",
      "Legit recruiters will NEVER ask you to pay an 'upfront processing fee' to get hired.",
      "Always check the sender's actual email address, not just their display name.",
      "Enable Two-Factor Authentication (2FA) on your email. It stops 99% of automated attacks.",
      "AI deepfakes often struggle with blinking and teeth. Watch the video closely!",
      "If a WhatsApp message offers RM500/day just to 'like' videos, it's a guaranteed task scam.",
      "Never use the same password for your email and your bank account."
    ];

    int dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    return tips[dayOfYear % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Scaffold(body: Center(child: Text("Please log in.")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Clean, bright background
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {

            String displayUsername = username;
            String? avatarPath;
            int strictCompletedModules = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              displayUsername = userData['username'] ?? username;
              avatarPath = userData['avatar'];

              // --- CALCULATE RANK FOR AVATAR BADGE ---
              Map<String, dynamic>? quizScores = userData['quiz_scores'] as Map<String, dynamic>?;
              if (quizScores != null) {
                if (quizScores.containsKey("Job Scams Assessment")) strictCompletedModules++;
                if (quizScores.containsKey("Phishing Assessment")) strictCompletedModules++;
                if (quizScores.containsKey("Deepfake Assessment")) strictCompletedModules++;
              }
            }

            // Determine badge appearance based on progress
            IconData rankIcon = Icons.person_outline;
            Color rankColor = Colors.blueGrey;

            if (strictCompletedModules == 1) {
              rankIcon = Icons.security;
              rankColor = Colors.blueAccent;
            } else if (strictCompletedModules == 2) {
              rankIcon = Icons.shield_outlined;
              rankColor = Colors.indigoAccent;
            } else if (strictCompletedModules >= 3) {
              rankIcon = Icons.verified_user;
              rankColor = Colors.purpleAccent;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DASHBOARD HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: TextStyle(fontSize: 14, color: Colors.blueGrey[400], fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayUsername,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // --- UPDATED AVATAR WITH RANK BADGE ---
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            backgroundImage: avatarPath != null ? AssetImage(avatarPath) : null,
                            child: avatarPath == null
                                ? const Icon(Icons.person, color: Colors.blue, size: 30)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: rankColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(rankIcon, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. HERO ACTION CARD (The Daily Mix)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigoAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${DateFormat('MMMM d').format(DateTime.now()).toUpperCase()} CHALLENGE",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text("The Daily Mix", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                        const SizedBox(height: 4),
                        Text("5 randomized questions to keep your skills sharp.", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 160,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const QuizPage(chapterName: "Daily Mix")
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigoAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Start Quiz", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(width: 6),
                                Icon(Icons.bolt_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. DAILY CYBER TIP BANNER ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.orange, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("TIP OF THE DAY", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(
                                _getDailyTip(),
                                style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. MODULES GRID
                  const Text("Learning Modules", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      // --- 1. JOB SCAMS MODULE ---
                      _buildModuleCard(
                        context: context,
                        title: "Job Scams",
                        icon: Icons.work_off,
                        color: Colors.redAccent,
                        targetPage: const VideoPlayerPage(
                          videoTitle: "Job Scams",
                          videoDescription: "In this module, you will learn the top 3 red flags of fake recruitment offers in Malaysia, including upfront payments and suspicious WhatsApp interviews.",
                          videoUrl: 'assets/videos/Job_Scam.mp4',
                          linkedQuizPage: QuizPage(chapterName: "Job Scams Assessment"),
                        ),
                      ),
                      // --- 2. PHISHING MODULE ---
                      _buildModuleCard(
                        context: context,
                        title: "Phishing",
                        icon: Icons.phishing,
                        color: Colors.orange,
                        targetPage: const VideoPlayerPage(
                          videoTitle: "Phishing 101",
                          videoDescription: "Analyze real-world phishing emails and malicious links to avoid giving away your credentials to fake websites.",
                          videoUrl: 'assets/videos/Online_Investment_Scam.mp4',
                          linkedQuizPage: QuizPage(chapterName: "Phishing Assessment"),
                        ),
                      ),
                      // --- 3. DEEPFAKES MODULE ---
                      _buildModuleCard(
                        context: context,
                        title: "Deepfakes",
                        icon: Icons.face_retouching_off,
                        color: Colors.purple,
                        targetPage: const VideoPlayerPage(
                          videoTitle: "Deepfakes",
                          videoDescription: "Learn to identify unnatural blinking, audio glitches, and other common deepfake flaws.",
                          videoUrl: 'assets/videos/Deepfake.mp4',
                          linkedQuizPage: QuizPage(chapterName: "Deepfake Assessment"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WHITE CARDS WITH COLORED SHADOWS ---
  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget targetPage,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Crisp white card
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.2), // The beautiful colored shadow!
                blurRadius: 15,
                offset: const Offset(0, 8)
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}