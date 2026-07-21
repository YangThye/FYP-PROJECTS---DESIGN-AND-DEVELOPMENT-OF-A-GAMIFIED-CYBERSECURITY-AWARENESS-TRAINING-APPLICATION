import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'login_page.dart';
import 'edit_profile_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  // --- DEVELOPER TOOL TO WIPE PROGRESS ---
  Future<void> _resetAccountProgress(String uid) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Reset Progress?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text("This will permanently wipe all your quiz scores, unlocked videos, and initialization data. Are you sure?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Wipe Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'onboarding_complete': FieldValue.delete(),
        'experience_level': FieldValue.delete(),
        'baseline_score': FieldValue.delete(),
        'baseline_total': FieldValue.delete(),
        'unlocked_videos': FieldValue.delete(),
        'quiz_scores': FieldValue.delete(),
        'quizzes_completed': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account reset successfully! Logging out..."), backgroundColor: Colors.green),
        );
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error resetting data: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: Text("No user logged in.")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Error fetching account details."));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            String realUsername = userData['username'] ?? "Unknown User";
            String realEmail = userData['email'] ?? currentUser.email ?? "No Email";
            String? avatarPath = userData['avatar'];
            String? gender = userData['gender'];
            String? birthdayStr = userData['birthday'];

            // Safe fallback to 0 if the user hasn't taken the baseline yet
            int baselineScore = userData['baseline_score'] ?? 0;

            DateTime? birthdayDate;
            if (birthdayStr != null) birthdayDate = DateFormat('yyyy-MM-dd').parse(birthdayStr);

            // =========================================================
            // --- THE SMART RANK & XP SYSTEM ---
            // =========================================================
            Map<String, dynamic>? quizScores = userData['quiz_scores'] as Map<String, dynamic>?;

            int strictCompletedModules = 0;
            int totalQuizPoints = 0;

            // 1. Check which modules they actually completed and tally their quiz XP
            if (quizScores != null) {
              if (quizScores.containsKey("Job Scams Assessment")) {
                strictCompletedModules++;
                totalQuizPoints += (quizScores["Job Scams Assessment"] as num).toInt();
              }
              // --- FIX: Updated the key name below ---
              if (quizScores.containsKey("Phishing Assessment")) {
                strictCompletedModules++;
                totalQuizPoints += (quizScores["Phishing Assessment"] as num).toInt();
              }
              // --- FIX: Updated the key name below ---
              if (quizScores.containsKey("Deepfake Assessment")) {
                strictCompletedModules++;
                totalQuizPoints += (quizScores["Deepfake Assessment"] as num).toInt();
              }
            }

            // 2. Total XP = Preliminary Aptitude Test + Module Quiz Scores
            int totalXP = baselineScore + totalQuizPoints;
            int maxXP = 35; // 5 from baseline + 30 from quizzes

            // 3. Progress is based strictly on completing the 3 modules!
            int totalModules = 3;
            double progress = (strictCompletedModules / totalModules).clamp(0.0, 1.0);

            String rankTitle = "Civilian";
            String levelDisplay = "LEVEL 1";
            IconData rankIcon = Icons.person_outline;
            Color rankColor = Colors.blueGrey;

            if (strictCompletedModules == 1) {
              rankTitle = "Field Agent";
              levelDisplay = "LEVEL 2";
              rankIcon = Icons.security;
              rankColor = Colors.blueAccent;
            } else if (strictCompletedModules == 2) {
              rankTitle = "Senior Agent";
              levelDisplay = "LEVEL 3";
              rankIcon = Icons.shield_outlined;
              rankColor = Colors.indigoAccent;
            } else if (strictCompletedModules >= 3) {
              rankTitle = "Cyber Guardian";
              levelDisplay = "MAX RANK";
              rankIcon = Icons.verified_user;
              rankColor = Colors.purpleAccent;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 130.0),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // --- PROFILE HEADER WITH AVATAR ---
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        backgroundImage: avatarPath != null ? AssetImage(avatarPath) : null,
                        child: avatarPath == null
                            ? const Icon(Icons.person, size: 60, color: Colors.blue)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(rankIcon, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(realUsername, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(realEmail, style: TextStyle(fontSize: 16, color: Colors.grey[600])),

                  if (gender != null || birthdayStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${gender ?? ''} ${birthdayStr != null ? '• $birthdayStr' : ''}",
                        style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                      ),
                    ),

                  // --- TOTAL XP BADGE ---
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade700, width: 1.5)
                    ),
                    child: Text(
                      "TOTAL MASTERY: $totalXP XP",
                      style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // --- ACHIEVEMENTS & BADGES SECTION ---
                  // ==========================================
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                          child: Text("ACHIEVEMENTS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildBadge(
                                icon: Icons.flag,
                                label: "The Initiate",
                                color: Colors.blue,
                                isEarned: baselineScore > 0,
                              ),
                              _buildBadge(
                                icon: Icons.work_off,
                                label: "Scam Buster",
                                color: Colors.orange,
                                isEarned: quizScores?["Job Scams Assessment"] == 10,
                              ),
                              _buildBadge(
                                icon: Icons.phishing,
                                label: "Phish Catcher",
                                color: Colors.red,
                                // --- FIX: Updated the key name below ---
                                isEarned: quizScores?["Phishing Assessment"] == 10,
                              ),
                              _buildBadge(
                                icon: Icons.face_retouching_off,
                                label: "Glitch Hunter",
                                color: Colors.purple,
                                // --- FIX: Updated the key name below ---
                                isEarned: quizScores?["Deepfake Assessment"] == 10,
                              ),
                              _buildBadge(
                                icon: Icons.diamond,
                                label: "Perfection",
                                color: Colors.amber,
                                isEarned: totalXP == maxXP, // 35 / 35
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- THE DYNAMIC SECURITY CLEARANCE CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rankColor.withValues(alpha: 0.9), rankColor.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: rankColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("SECURITY CLEARANCE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text(levelDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(rankTitle, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 24),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              minHeight: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                              strictCompletedModules == totalModules
                                  ? "All Core Modules Completed!"
                                  : "$strictCompletedModules / $totalModules Core Modules Completed",
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text("ATTITUDE • ABILITY • AMBITION",
                              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- BASELINE SCORE MINI-CARD ---
                  if (userData.containsKey('baseline_score')) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.assignment_turned_in, color: Colors.orange),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Aptitude Head Start", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Bonus XP from initialization", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(
                              "+$baselineScore XP",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange)
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // --- SETTINGS LIST ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(
                              currentUsername: realUsername,
                              currentGender: gender,
                              currentBirthday: birthdayDate,
                              currentAvatar: avatarPath,
                            )));
                          },
                        ),
                        const Divider(height: 1, indent: 50),

                        ListTile(
                          leading: const Icon(Icons.lock, color: Colors.blue),
                          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () async {
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: realEmail);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent!"), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              debugPrint("Error: $e");
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 50),

                        // ========================================================
                        // --- DEV TOOLS HIDDEN FOR PRODUCTION / UAT TESTING ---
                        // Change this boolean to 'true' if you need them back!
                        // ========================================================
                        if (false) ...[
                          ListTile(
                            leading: const Icon(Icons.download_rounded, color: Colors.indigo),
                            title: const Text("DEV: Export Quizzes to Console"),
                            onTap: () async => await fetchAndPrintAllQuizzes(context),
                          ),
                          const Divider(height: 1, indent: 50),

                          ListTile(
                            leading: const Icon(Icons.cloud_upload, color: Colors.blueGrey),
                            title: const Text("DEV: Upload All Quizzes"),
                            onTap: () async => await uploadQuizzesToFirebase(context),
                          ),
                          const Divider(height: 1, indent: 50),

                          ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            title: const Text("DEV: Reset Account Progress"),
                            onTap: () => _resetAccountProgress(currentUser.uid),
                          ),
                          const Divider(height: 1, indent: 50),
                        ],

                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- HELPER WIDGET FOR DRAWING BADGES ---
  Widget _buildBadge({required IconData icon, required String label, required Color color, required bool isEarned}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isEarned ? color.withValues(alpha: 0.15) : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: isEarned ? color : Colors.grey.shade300,
                width: isEarned ? 2 : 1,
              ),
              boxShadow: isEarned ? [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)
              ] : [],
            ),
            child: Icon(
              isEarned ? icon : Icons.lock,
              color: isEarned ? color : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
              color: isEarned ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- RUN THIS ONCE TO BUILD YOUR DATABASE ---
Future<void> uploadQuizzesToFirebase(BuildContext context) async {
  final Map<String, List<Map<String, dynamic>>> allQuizzes = {
    "Deepfake Assessment": [
      {
        "answerIndex": 0,
        "question": "What is a common visual flaw in a deepfake video?",
        "options": ["Unnatural blinking or blurry edges around the face", "Perfect lighting", "High resolution background", "Loud background noise"]
      },
      {
        "answerIndex": 1,
        "question": "If you suspect a voice note from a friend asking for money is AI-generated, you should:",
        "options": ["Send the money just in case", "Call them directly to verify their situation", "Ignore the message completely", "Forward it to other friends"]
      },
      {
        "answerIndex": 2,
        "question": "What happens when someone in a poorly made deepfake video turns their head sideways?",
        "options": ["The video quality improves", "The video mutes automatically", "The AI face tracking often glitches or warps", "The background changes color"]
      },
      {
        "answerIndex": 3,
        "question": "Which audio clue suggests a voice might be a deepfake?",
        "options": ["Speaking too quickly", "Using slang words", "Having background cafe noise", "A robotic, flat tone with unnatural breathing pauses"]
      },
      {
        "answerIndex": 0,
        "question": "Scammers often use deepfakes on video calls to impersonate:",
        "options": ["Celebrities, politicians, or kidnapped family members", "Random strangers", "Customer service bots", "Cartoon characters"]
      },
      {
        "answerIndex": 1,
        "question": "Look at the mouth of a suspected deepfake. What might you notice?",
        "options": ["The teeth look perfectly straight", "The lip-syncing does not match the words perfectly", "The lips are always closed", "They smile too much"]
      },
      {
        "answerIndex": 2,
        "question": "Why do scammers use deepfakes in investment scams?",
        "options": ["To make the video file smaller", "To hide the background", "To impersonate famous billionaires endorsing a fake crypto coin", "To make the video load faster"]
      },
      {
        "answerIndex": 3,
        "question": "If you see a politician saying something outrageous on social media, you should first:",
        "options": ["Share it immediately", "Assume it is 100% true", "Leave an angry comment", "Check reputable news sources to verify if they actually said it"]
      },
      {
        "answerIndex": 0,
        "question": "What is a good 'challenge' to give someone on a video call if you think they are a deepfake?",
        "options": ["Ask them to wave their hand slowly in front of their face", "Ask them what time it is", "Ask them to speak louder", "Ask them to type a message"]
      },
      {
        "answerIndex": 1,
        "question": "Deepfakes are created using what technology?",
        "options": ["Basic Photoshop", "Artificial Intelligence and Machine Learning", "Microsoft Word", "Standard video editing software"]
      },
      {
        "answerIndex": 2,
        "question": "Which facial feature do AI generators consistently struggle to render correctly?",
        "options": ["Noses", "Cheeks", "Ears and earrings", "Eyebrows"]
      },
      {
        "answerIndex": 3,
        "question": "How can lighting reveal a deepfake?",
        "options": ["The video is too bright", "The video is black and white", "There are no shadows anywhere", "Shadows on the face don't match the lighting in the background"]
      },
      {
        "answerIndex": 0,
        "question": "What is the 'Safe Word' strategy against voice cloning?",
        "options": ["Agreeing on a secret family word to verify identity during emergencies", "Using a strong password", "Saying 'safe' before every call", "Using encrypted apps"]
      },
      {
        "answerIndex": 1,
        "question": "If an AI voice clone claims your child is kidnapped, what is the scammers primary goal?",
        "options": ["To get you to call the police", "To induce panic so you transfer money without thinking", "To steal your identity", "To hack your phone"]
      },
      {
        "answerIndex": 2,
        "question": "Look closely at the subject's eyes in a suspected deepfake video. You might see:",
        "options": ["Red eye effect", "Perfectly round pupils", "Unnatural glare or eyes pointing in slightly different directions", "Eyes changing color"]
      },
      {
        "answerIndex": 3,
        "question": "What often happens to jewelry or glasses in a deepfake video?",
        "options": ["They look too shiny", "They change colors constantly", "They fall off", "They morph, blend into the skin, or disappear and reappear"]
      },
      {
        "answerIndex": 0,
        "question": "Why do scammers use deepfake live avatars in video interviews?",
        "options": ["To bypass biometric security or hide their true identity", "To look more professional", "To save internet bandwidth", "To test new technology"]
      },
      {
        "answerIndex": 1,
        "question": "How does asking a caller to turn their head 90 degrees help detect a deepfake?",
        "options": ["It improves audio quality", "2D deepfake masks struggle with full profile views and often tear or warp", "It changes the lighting", "It forces them to drop the call"]
      },
      {
        "answerIndex": 2,
        "question": "What is a common audio glitch in a cloned voice?",
        "options": ["Loud static", "Echoing", "Inconsistent pitch and lack of natural emotion or breathing", "Background music playing"]
      },
      {
        "answerIndex": 3,
        "question": "Can deepfakes be used to bypass facial recognition security?",
        "options": ["Never", "Only on old phones", "Yes, but only in movies", "Yes, sophisticated deepfakes can spoof poorly secured biometric systems"]
      },
      {
        "answerIndex": 0,
        "question": "What should you look for around the neck in a deepfake video?",
        "options": ["A harsh line or blur where the fake face meets the real body", "A visible zipper", "Tattoos", "Excessive sweating"]
      },
      {
        "answerIndex": 1,
        "question": "If a famous CEO asks you for gift cards via a video message, it is:",
        "options": ["A special company reward", "A guaranteed deepfake scam", "A tax deduction method", "A new corporate strategy"]
      },
      {
        "answerIndex": 2,
        "question": "How are deepfake voice clones usually created?",
        "options": ["By hiring voice actors", "By recording phone calls", "By feeding a few seconds of a person's public audio into an AI model", "By using a voice changer app"]
      },
      {
        "answerIndex": 3,
        "question": "Which of these is NOT a reliable way to spot a deepfake?",
        "options": ["Looking for unnatural blinking", "Watching for morphing glitches", "Listening for robotic tones", "Checking if the video is in 4K resolution"]
      },
      {
        "answerIndex": 0,
        "question": "What is 'Generative AI' in the context of deepfakes?",
        "options": ["Algorithms that learn to generate new, realistic audio or video from training data", "A type of camera", "A video editing platform", "A firewall protection"]
      },
      {
        "answerIndex": 1,
        "question": "Why are deepfakes dangerous for elections?",
        "options": ["They use too much electricity", "They can spread highly convincing misinformation about candidates", "They break voting machines", "They steal voter data"]
      },
      {
        "answerIndex": 2,
        "question": "If you spot a deepfake scam ad on social media, you should:",
        "options": ["Share it to warn others", "Comment that it is fake", "Report the ad to the platform and block the account", "Click it to see where it goes"]
      },
      {
        "answerIndex": 3,
        "question": "What happens to the background when a deepfake subject moves rapidly?",
        "options": ["The background stays perfectly still", "The background turns black", "The background changes locations", "The background often warps or pulls along with the edges of the face"]
      },
      {
        "answerIndex": 0,
        "question": "How do deepfake scammers get the audio to clone your voice?",
        "options": ["From your public social media videos or answering your phone and talking to them", "From your text messages", "From your bank", "From your fingerprint"]
      },
      {
        "answerIndex": 1,
        "question": "What is the best defense against deepfake social engineering?",
        "options": ["Buying expensive antivirus", "Verifying the request through a secondary, trusted communication channel", "Never using video calls", "Watermarks are too expensive"]
      },
      {
        "answerIndex": 2,
        "question": "If a company CEO's voice requests an urgent wire transfer via a phone call, what must an employee do?",
        "options": ["Transfer the funds immediately", "Ignore the call", "Verify by hanging up and calling the CEO back on a known, official internal number", "Send an email confirming the transfer"]
      },
      {
        "answerIndex": 3,
        "question": "What is the role of the 'Discriminator' in the GAN technology used to make deepfakes?",
        "options": ["It generates the fake image", "It deletes bad images", "It adds audio to the video", "It acts as a detective, trying to tell the fake images from real ones until the fakes are perfect"]
      },
      {
        "answerIndex": 0,
        "question": "Look at the hair in a deepfake video. What is a common artifact?",
        "options": ["Individual hair strands look blurry, static, or merge unnaturally with the background", "The hair is too long", "The hair changes color", "The hair is perfectly styled"]
      },
      {
        "answerIndex": 1,
        "question": "Why do deepfake videos often have the subject looking straight ahead?",
        "options": ["It is more dramatic", "Side profiles and extreme angles break the 2D facial mapping of most AI models", "It is required by the software", "It saves processing power"]
      },
      {
        "answerIndex": 2,
        "question": "Can AI deepfake technology operate in real-time?",
        "options": ["No, it takes days to render", "Only for audio", "Yes, tools exist that can swap faces and voices live during a Zoom or Skype call", "Only for video"]
      },
      {
        "answerIndex": 3,
        "question": "What should you do if you find a deepfake of yourself online?",
        "options": ["Ignore it", "Pay the creator to take it down", "Make a deepfake of them in return", "Report it to the platform, document the URL, and contact authorities (e.g., MCMC in Malaysia)"]
      },
      {
        "answerIndex": 0,
        "question": "How does deepfake audio usually handle breathing and mouth noises?",
        "options": ["It often omits natural human breathing, sighs, and subtle mouth clicks", "It makes them very loud", "It replaces them with music", "It handles them perfectly"]
      },
      {
        "answerIndex": 1,
        "question": "Why are elderly people particularly vulnerable to deepfake voice scams?",
        "options": ["They don't use phones", "They may have declining hearing and are less aware of modern AI cloning capabilities", "They have more money", "They answer all calls"]
      },
      {
        "answerIndex": 2,
        "question": "What is 'Synthesia' or 'HeyGen' in the context of AI?",
        "options": ["Antivirus software", "Hacking groups", "Legitimate platforms that generate AI video avatars, which scammers sometimes abuse", "Types of malware"]
      },
      {
        "answerIndex": 3,
        "question": "If a video seems slightly 'off' but you can't pinpoint why, what is the safest assumption?",
        "options": ["It's just a bad camera", "Ignore your feeling and trust the video", "Assume it's a Hollywood movie", "Trust your gut instinct (the 'uncanny valley' effect) and verify the source"]
      },
      {
        "answerIndex": 0,
        "question": "What is the ultimate goal of educating yourself about deepfakes?",
        "options": ["To build a healthy 'zero-trust' mindset and verify digital identities before taking action", "To become an AI developer", "To stop using the internet", "To win online arguments"]
      },
      {
        "answerIndex": 1,
        "question": "What makes deepfake technology so highly accessible to scammers today?",
        "options": ["They are all computer geniuses", "Open-source AI models and cheap cloud computing allow anyone to create them", "They steal the technology from the government", "It actually costs millions of dollars"]
      },
      {
        "answerIndex": 2,
        "question": "Can you absolutely rely on invisible AI watermarks to detect if an image is a deepfake?",
        "options": ["Yes, watermarks are foolproof", "Yes, they glow in the dark", "No, malicious actors actively strip or bypass watermarks using open-source tools", "Only on mobile phones"]
      },
      {
        "answerIndex": 3,
        "question": "When looking at a suspected AI-generated image, why should you closely examine the subject's hands?",
        "options": ["To see if they are wearing expensive rings", "To check for fingerprints", "To see if the lighting matches", "AI models frequently struggle with complex hand geometry, resulting in six fingers or melted joints"]
      },
      {
        "answerIndex": 0,
        "question": "If there is a billboard or a street sign in the background of a deepfake video, what usually happens to the text?",
        "options": ["It often appears as gibberish, warped alien-like letters, or misspelled words", "It is perfectly clear and readable", "It translates into different languages automatically", "It is always blurred out by the AI"]
      },
      {
        "answerIndex": 1,
        "question": "The vast majority of deepfakes created globally are used for what malicious purpose?",
        "options": ["Creating fake movie trailers", "Non-consensual synthetic pornography and targeted sextortion", "Robbing banks", "Cheating in video games"]
      },
      {
        "answerIndex": 2,
        "question": "Why do deepfake audio calls from 'family members' almost always involve a massive emergency (like an accident or arrest)?",
        "options": ["Because emergencies are easier to fake", "Because the AI can only generate angry voices", "Panic overrides your critical thinking, preventing you from noticing the robotic tone or audio glitches", "It is a legal requirement for scammers"]
      },
      {
        "answerIndex": 3,
        "question": "How do banking apps try to defeat deepfakes during the 'liveness check' phase of opening an account?",
        "options": ["By asking for your password", "By checking your credit score", "By making you type a captcha", "By requiring you to smile, blink, or turn your head to detect 3D depth and blood flow"]
      },
      {
        "answerIndex": 0,
        "question": "What is the difference between a 'Deepfake' and a 'Cheapfake'?",
        "options": ["Cheapfakes use basic editing (like slowing down real video to make someone look drunk), while Deepfakes use AI generation", "Cheapfakes are free, Deepfakes cost money", "Deepfakes only work on the dark web", "There is no difference"]
      },
      {
        "answerIndex": 1,
        "question": "If you are on a phone call with a suspected real-time voice clone, what is a subtle technical clue to listen for?",
        "options": ["The voice sounds too loud", "Unnatural lag or latency in their responses because the AI takes a few seconds to process and generate the audio", "They speak in a different language", "There is absolutely no background noise"]
      }
    ],
    "Job Scams Assessment": [
      {
        "answerIndex": 1,
        "question": "A recruiter messages you on WhatsApp offering RM500/day just to 'like' YouTube videos. What is this?",
        "options": ["A legitimate marketing job", "A classic task scam", "A government initiative", "A freelance gig"]
      },
      {
        "answerIndex": 2,
        "question": "The 'employer' says you are hired, but you must pay RM150 for a 'training kit' first. What should you do?",
        "options": ["Pay the fee quickly to secure the job", "Ask if you can pay in installments", "Block the number immediately", "Give them your bank login details instead"]
      },
      {
        "answerIndex": 3,
        "question": "Which of these is the biggest red flag for a fake job offer?",
        "options": ["They ask for an interview", "They require a resume", "They have an official company email address", "They guarantee extremely high pay for zero experience"]
      },
      {
        "answerIndex": 0,
        "question": "You receive a job offer email from 'hr-petronas@gmail.com'. Why is this suspicious?",
        "options": ["Big companies use their own domain (e.g., @petronas.com), not Gmail", "Petronas only hires via LinkedIn", "The email is too short", "It is not suspicious at all"]
      },
      {
        "answerIndex": 1,
        "question": "A recruiter asks for your bank account username, password, and a TAC code to 'setup your payroll'. You should:",
        "options": ["Give it to them so you can get paid", "Refuse and report them, employers never need your password", "Only give the TAC code", "Give them a fake password"]
      },
      {
        "answerIndex": 2,
        "question": "What is a 'Mule Account' in the context of job scams?",
        "options": ["A premium bank account", "A savings account for farmers", "An account used by scammers to launder stolen money through you", "An account that earns extra interest"]
      },
      {
        "answerIndex": 3,
        "question": "The job description is extremely vague, just saying 'Work from home, earn thousands'. This is likely designed to:",
        "options": ["Save space on the job board", "Keep company secrets safe", "Target highly skilled professionals", "Lure in as many desperate victims as possible"]
      },
      {
        "answerIndex": 0,
        "question": "They want to hire you on the spot without a voice or video interview, only using Telegram text messages. Is this normal?",
        "options": ["No, legitimate companies will conduct proper interviews", "Yes, modern companies prefer text", "Yes, if it is a tech company", "Only for part-time jobs"]
      },
      {
        "answerIndex": 1,
        "question": "You are 'accidentally' overpaid for your first freelance task, and they ask you to refund the extra via a wire transfer. What is happening?",
        "options": ["They made an honest accounting mistake", "It is an overpayment scam using a stolen credit card", "It is a test of your honesty", "They are giving you a bonus"]
      },
      {
        "answerIndex": 2,
        "question": "A recruiter pressures you, saying 'You must accept this offer and pay the registration fee in the next 10 minutes or lose the job.'",
        "options": ["You should pay immediately to show commitment", "It is a highly competitive job", "Scammers use artificial urgency to make you panic", "They are just testing your typing speed"]
      },
      {
        "answerIndex": 3,
        "question": "What is the CCID 'Semak Mule' portal used for in Malaysia?",
        "options": ["To check your credit score", "To apply for jobs", "To pay your taxes", "To verify if a bank account or phone number has been reported for scams"]
      },
      {
        "answerIndex": 0,
        "question": "A job requires you to buy products on a fake e-commerce site to 'boost their ratings', promising a refund plus commission. This is a:",
        "options": ["Task/Mission scam", "Dropshipping business", "Affiliate marketing job", "Retail arbitrage"]
      },
      {
        "answerIndex": 1,
        "question": "Why do task scammers actually pay you for the first few small tasks?",
        "options": ["They are generous", "To build false trust so you will deposit a much larger sum later", "They made a mistake", "It is a legal requirement"]
      },
      {
        "answerIndex": 2,
        "question": "What is the consequence of letting a scammer use your bank account (becoming a Money Mule)?",
        "options": ["You get a free commission", "Your account gets upgraded", "You can be arrested, charged with money laundering, and blacklisted by banks", "Nothing, it's the scammer's fault"]
      },
      {
        "answerIndex": 3,
        "question": "You are added to a WhatsApp group named 'Shopee VIP Task Force 88' without your consent. You should:",
        "options": ["Introduce yourself", "Wait to see the tasks", "Message the admin privately", "Immediately report and exit the group"]
      },
      {
        "answerIndex": 0,
        "question": "An employer asks for a photocopy of your IC (front and back) before you have even been interviewed. What is the risk?",
        "options": ["Identity theft to open loan or mule accounts in your name", "They want to check your age", "They want to mail you a gift", "There is no risk"]
      },
      {
        "answerIndex": 1,
        "question": "If a recruiter's profile picture is a very blurry logo or an overly perfect model photo, it is likely:",
        "options": ["Taken by a professional", "A stolen image or AI-generated fake profile", "A company policy", "A compressed image"]
      },
      {
        "answerIndex": 2,
        "question": "What is the National Scam Response Centre (NSRC) hotline number in Malaysia?",
        "options": ["999", "112", "997", "119"]
      },
      {
        "answerIndex": 3,
        "question": "A job ad says 'Earn RM8,000 monthly part-time data entry'. Why is this a red flag?",
        "options": ["Data entry is too hard", "SSM certificates cannot be faked", "You should frame it", "The salary is completely disproportionate to the unskilled nature of the work"]
      },
      {
        "answerIndex": 0,
        "question": "You get an email saying 'Your resume was reviewed and you are hired for the Remote Admin role.' but you never applied.",
        "options": ["It is a mass-phishing scam targeting thousands of people at random", "You got lucky", "Your friend recommended you", "LinkedIn shared your profile"]
      },
      {
        "answerIndex": 1,
        "question": "If a job requires you to convert your own money into Cryptocurrency and send it to a 'company wallet', it is:",
        "options": ["A modern tech job", "A money laundering or investment scam", "A banking role", "A stock market test"]
      },
      {
        "answerIndex": 2,
        "question": "What is a 'Drop-shipping Agent' scam?",
        "options": ["A legitimate logistics role", "A shipping company", "You are forced to buy expensive inventory upfront for a fake online store that will never get customers", "A warehouse manager job"]
      },
      {
        "answerIndex": 3,
        "question": "The job platform they want you to use looks exactly like Lazada, but the URL is 'lazada-vip-task.com'.",
        "options": ["It is a special VIP server", "It is a backup website", "It is a new branch", "It is a spoofed phishing site designed to steal credentials and money"]
      },
      {
        "answerIndex": 0,
        "question": "A recruiter threatens legal action or says they will call the police if you stop doing tasks and don't pay the penalty fee.",
        "options": ["It is an empty scare tactic; block them immediately and report to NSRC", "You must pay to avoid jail", "Hire a lawyer immediately", "Apologize and pay"]
      },
      {
        "answerIndex": 1,
        "question": "What does a legitimate job onboarding process look like?",
        "options": ["Transferring RM50 to HR", "Signing a formal contract, providing EPF/SOCSO details, and receiving official company emails", "Providing bank details on Telegram", "No paperwork at all"]
      },
      {
        "answerIndex": 2,
        "question": "You are asked to receive money into your bank and use it to buy gift cards (iTunes/Google Play) to send to the employer.",
        "options": ["It is a corporate gifting job", "It is a rewards program", "You are acting as a money mule to launder stolen funds", "It is a tax loophole"]
      },
      {
        "answerIndex": 3,
        "question": "Why do scammers prefer Telegram over traditional communication?",
        "options": ["It has better emojis", "It is faster", "It uses less data", "It allows them to hide their phone numbers and delete chat histories on both sides"]
      },
      {
        "answerIndex": 0,
        "question": "If a recruiter gets angry or defensive when you ask basic questions about the company address or directors:",
        "options": ["It is a major red flag; legitimate HR professionals are transparent", "They are just stressed", "You should apologize", "They are testing your loyalty"]
      },
      {
        "answerIndex": 1,
        "question": "A job ad on Facebook has the comments disabled. Why?",
        "options": ["To keep it clean", "To prevent previous victims from warning others that it is a scam", "Facebook policy", "To save server space"]
      },
      {
        "answerIndex": 2,
        "question": "You are told you made a mistake on a 'task' and must pay a RM1000 'recovery fee' to fix the system.",
        "options": ["Pay it so you don't get fired", "Ask the boss to deduct it from your salary", "It is a psychological trap to squeeze more money out of a sunk-cost fallacy", "Fix the system yourself"]
      },
      {
        "answerIndex": 3,
        "question": "How can you verify a job offer from a major company?",
        "options": ["Ask the recruiter to promise they are real", "Look at their WhatsApp profile picture", "Trust the PDF they sent", "Go to the company's official website careers page and apply there directly"]
      },
      {
        "answerIndex": 0,
        "question": "A job requires you to use your personal Facebook account to post hundreds of property rental ads.",
        "options": ["You are being used to facilitate rental scams; your account will get banned", "A marketing internship", "A real estate job", "A social media manager role"]
      },
      {
        "answerIndex": 1,
        "question": "What is the danger of providing a 'selfie holding your IC' to an unknown recruiter?",
        "options": ["They will laugh at the photo", "The photo will be used to bypass e-KYC security on banking apps or crypto exchanges to open accounts in your name", "They will post it on Instagram", "There is no danger"]
      },
      {
        "answerIndex": 2,
        "question": "If you realize you have fallen for a job scam and already transferred money, your FIRST step is to:",
        "options": ["Delete the chat", "Message the scammer asking for it back", "Call 997 (NSRC) or your bank immediately to attempt to freeze the transaction", "Keep quiet"]
      },
      {
        "answerIndex": 3,
        "question": "A legitimate company will NEVER ask you to pay for:",
        "options": ["Your own lunch", "Your transport to work", "Professional clothing", "A 'Background Check' or 'Job Placement' fee upfront"]
      },
      {
        "answerIndex": 0,
        "question": "Why do scammers use 'Combination Tasks' (e.g., 3 normal tasks, 1 expensive task)?",
        "options": ["To get you hooked with small wins before forcing a massive payment to complete the 'set'", "To make the job interesting", "To test your math skills", "Company policy"]
      },
      {
        "answerIndex": 1,
        "question": "The recruiter's grammar is terrible, full of typos, and uses weird capitalization.",
        "options": ["They are just typing fast", "Poor grammar is a common hallmark of overseas scam syndicates", "It is modern internet slang", "They are using a broken keyboard"]
      },
      {
        "answerIndex": 2,
        "question": "A job claims to be endorsed by a famous celebrity in a video. Should you trust it?",
        "options": ["Yes, celebrities never lie", "Yes, if the video has high views", "No, it could be a deepfake or unauthorized use of their image", "Only if it is on YouTube"]
      },
      {
        "answerIndex": 3,
        "question": "You are offered a 'Typing Job' converting images to text, but must pay RM50 for the 'software'.",
        "options": ["Pay it, typing jobs are great", "Ask for a free trial", "Share the software with friends", "This is an ancient scam; free OCR technology exists, nobody pays humans high rates for basic typing anymore"]
      },
      {
        "answerIndex": 0,
        "question": "What is the 'Sunk Cost Fallacy' in task scams?",
        "options": ["The psychological urge to keep paying fees because you have already invested so much and want it back", "A banking error", "A legal term", "A type of crypto coin"]
      },
      {
        "answerIndex": 1,
        "question": "A recruiter asks you to log into a specific Apple ID or Google account to 'test an app'.",
        "options": ["Do it to show your skills", "It is a device hijacking scam; they will lock your phone and demand ransom", "It is a standard QA tester job", "Only do it on an iPad"]
      },
      {
        "answerIndex": 2,
        "question": "If an employer insists on communicating ONLY through private direct messages and refuses phone calls:",
        "options": ["They are shy", "They are in a meeting", "They are hiding their voice and location, typical of scammers", "They prefer writing"]
      },
      {
        "answerIndex": 3,
        "question": "What is the best mindset to have when searching for jobs online?",
        "options": ["Trust everyone", "Apply to everything blindly", "Pay whatever fees they ask", "If it sounds too good to be true, it absolutely is. Zero trust until verified."]
      },
      {
        "answerIndex": 0,
        "question": "How do job scammers often find their victims?",
        "options": ["By scraping resumes from job boards, running fake Facebook ads, and sending mass SMS", "By walking around malls", "Through traditional newspapers", "By calling home phones"]
      },
      {
        "answerIndex": 1,
        "question": "You successfully avoided a job scam. What should you do next?",
        "options": ["Nothing", "Report the number to Semak Mule, block them, and warn friends/family about the tactic", "Message them back to waste their time", "Change your phone number"]
      },
      {
        "answerIndex": 0,
        "question": "You are offered a high-paying 'Customer Service' job in a neighboring country. The recruiter says they will fly you there, but you must enter using a Tourist Visa.",
        "options": ["It is likely a human trafficking or forced scam compound trap (e.g., KK Garden)", "It is a standard procedure for expats", "It is a great opportunity to travel", "You should pack light"]
      },
      {
        "answerIndex": 1,
        "question": "A remote company sends you a large cheque to buy a 'home office setup', but insists you must wire the money to buy the equipment ONLY from their 'certified vendor'. What is the catch?",
        "options": ["The equipment is overpriced", "The cheque will bounce a few days later, and you will lose the real money you sent to the fake vendor", "You won't get to choose the laptop brand", "The vendor is probably out of stock"]
      },
      {
        "answerIndex": 2,
        "question": "You attend a 'job interview' that turns out to be a large group seminar where the main requirement to make money is recruiting your family and friends to join under you.",
        "options": ["It is a highly respected marketing firm", "It is a standard corporate retreat", "It is a disguised pyramid scheme or predatory multi-level marketing (MLM) trap", "It is a networking event"]
      },
      {
        "answerIndex": 3,
        "question": "To proceed with your job application, you are instructed to call a special 'tele-interview' phone number that starts with an unusual premium prefix.",
        "options": ["It is a high-tech automated interview system", "It is an international call center", "They are testing your communication skills", "It is a premium-rate number scam designed to charge massive fees per minute to your phone bill"]
      },
      {
        "answerIndex": 0,
        "question": "An online job application form asks for your standard resume, but also demands your mother's maiden name, your exact birth location, and your banking PIN.",
        "options": ["It is an identity harvesting scam designed to bypass security questions on your personal bank accounts", "They are conducting a very thorough background check", "It is required to register you for company health insurance", "They want to send you a surprise birthday gift"]
      }
    ],
    "Phishing Assessment": [
      {
        "answerIndex": 2,
        "question": "You click 'Log in with Google' on a new website, but the popup asks for permission to 'Read, send, and permanently delete all your emails.'",
        "options": ["It is a standard Terms of Service", "Google requires this for all apps", "It is OAuth phishing (Illicit Consent Grant) to hijack your account without a password", "You should accept if you trust the site"]
      },
      {
        "answerIndex": 3,
        "question": "You receive a phone call from someone claiming to be 'Microsoft Tech Support' saying your PC has a virus.",
        "options": ["Follow their instructions to fix it", "Ask them for their employee ID", "Pay the fee they ask for", "Hang up; Microsoft does not proactively call users about PC infections"]
      },
      {
        "answerIndex": 0,
        "question": "Your smartphone calendar suddenly fills up with events titled 'Your iPhone is infected! Click here to clean.'",
        "options": ["It is a Calendar Phishing spam attack exploiting default auto-add calendar settings", "Your phone is definitely infected", "You need to buy antivirus software", "It is a reminder from Apple"]
      },
      {
        "answerIndex": 1,
        "question": "A person holding a heavy box asks you to hold the secure office door open for them so they don't have to scan their badge.",
        "options": ["Hold the door to be polite", "Ask them to drop the box and scan their badge; it could be a physical phishing/tailgating attempt", "Hold the door and carry the box for them", "Ignore them completely"]
      },
      {
        "answerIndex": 2,
        "question": "You get a WhatsApp message with a link that immediately opens your banking app and pre-fills a transfer screen.",
        "options": ["It is a convenient new feature", "Your bank sent it to test your app", "It uses deep-linking to execute a malicious transaction; do not authorize it", "It is an app update"]
      },
      {
        "answerIndex": 3,
        "question": "You search for 'LHDN tax refund form' on a search engine and click the first link, but the site asks for your credit card details.",
        "options": ["LHDN charges a processing fee", "It is a premium tax service", "You should enter the details", "It is SEO Poisoning where scammers manipulate search results to rank a phishing site first"]
      },
      {
        "answerIndex": 0,
        "question": "Why is typosquatting (e.g., faceb00k.com) often more successful on mobile phones than on desktop computers?",
        "options": ["Mobile browsers often hide the full URL bar to save screen space making it harder to spot typos", "Mobile phones don't have antivirus", "Desktop computers are faster", "Mobile keyboards are smaller"]
      },
      {
        "answerIndex": 1,
        "question": "You get an email from 'security@rnaybank.com' (notice the 'rn' instead of 'm'). This is called:",
        "options": ["A typo by the bank", "Typosquatting/Phishing", "A totally secure email", "A network error"]
      },
      {
        "answerIndex": 2,
        "question": "Phishing emails usually rely on what psychological trick?",
        "options": ["Telling long, boring stories", "Asking you about your day", "Creating a false sense of extreme urgency or fear", "Providing too many verifiable facts"]
      },
      {
        "answerIndex": 3,
        "question": "You get an SMS: 'Pos Malaysia: Your package is stuck. Click here to pay RM2.00 clearance fee.'",
        "options": ["Pay it quickly to get your package", "Reply to the text asking for details", "Forward it to the police", "It is a Smishing (SMS phishing) scam to steal your credit card"]
      },
      {
        "answerIndex": 0,
        "question": "Before clicking a link in an email on your computer, you should always:",
        "options": ["Hover your mouse over the link to preview the actual destination URL", "Click it twice just in case", "Copy it and send it to a friend", "Close your eyes"]
      },
      {
        "answerIndex": 1,
        "question": "If an email tells you your bank account is locked, what is the safest way to check?",
        "options": ["Click the link in the email", "Open your official banking app or type the URL manually into your browser", "Reply with your password", "Wait a few days to see if it unlocks"]
      },
      {
        "answerIndex": 2,
        "question": "What does the term 'Spear Phishing' mean?",
        "options": ["Fishing with a spear", "Sending billions of emails at random", "A highly targeted phishing attack customized with specific details about you or your company", "Phishing over a phone call"]
      },
      {
        "answerIndex": 3,
        "question": "What is 'Whaling' in cybersecurity?",
        "options": ["Protecting the ocean", "A large-scale DDOS attack", "A type of antivirus", "A spear-phishing attack specifically targeting high-profile executives like CEOs or CFOs"]
      },
      {
        "answerIndex": 0,
        "question": "You scan a QR code on a parking meter to pay, but it takes you to a fake website that steals your credit card. This is called:",
        "options": ["Quishing (QR Phishing)", "QR hacking", "Barcode spoofing", "Square scam"]
      },
      {
        "answerIndex": 1,
        "question": "An email asks you to click a link to 'verify your account'. The display name says 'Microsoft', but the actual sender email is 'admin@micro-support-xyz.com'.",
        "options": ["It is safe because the display name is Microsoft", "It is a spoofed sender address; the actual email domain reveals it is a scam", "It is an internal Microsoft email", "You should reply to ask if they are real"]
      },
      {
        "answerIndex": 2,
        "question": "What is an Adversary-in-the-Middle (AitM) phishing attack?",
        "options": ["A physical attacker stealing your phone", "A virus that deletes files", "A fake website that intercepts your password AND your 2FA OTP code in real-time, passing them to the real site to steal your session", "A slow internet connection"]
      },
      {
        "answerIndex": 3,
        "question": "You receive a Word document named 'Salary_Adjustments_2026.doc'. When opened, it asks you to 'Enable Macros'. What should you do?",
        "options": ["Enable them to read the document", "Forward it to colleagues", "Change the font size", "Do not enable macros; they can execute malicious scripts to install ransomware"]
      },
      {
        "answerIndex": 0,
        "question": "Why is it dangerous to use the same password for your email and your online banking?",
        "options": ["If your email is phished, the hacker can use that same password to immediately access your bank", "It is hard to remember", "It is not dangerous", "The bank will block it"]
      },
      {
        "answerIndex": 1,
        "question": "A website URL uses Cyrillic letters that look exactly like English letters (e.g., apple.com but the 'a' is a Russian character). This is a:",
        "options": ["Language bug", "Homograph attack used to trick users into thinking they are on a legitimate site", "Translation feature", "Browser error"]
      },
      {
        "answerIndex": 2,
        "question": "You get a text: 'Netflix: Payment declined. Update billing info at netflix-update-acc.com'.",
        "options": ["Update your info so you can watch movies", "Call your bank to complain", "It is a Smishing scam; log into Netflix directly via the official app to check", "Reply 'STOP'"]
      },
      {
        "answerIndex": 3,
        "question": "Why do phishing emails often contain deliberate spelling or grammar mistakes?",
        "options": ["Hackers are bad at spelling", "To bypass spam filters", "To make it look authentic", "To filter out cautious people; anyone who ignores the bad grammar is more likely to fall for the rest of the scam"]
      },
      {
        "answerIndex": 0,
        "question": "You receive a message from your 'boss' on WhatsApp asking you to urgently buy 10 Apple gift cards for a client presentation.",
        "options": ["It is an impersonation scam; verify by calling your boss or talking to them in person", "Buy them immediately to impress your boss", "Buy Google Play cards instead", "Ask HR for the money first"]
      },
      {
        "answerIndex": 1,
        "question": "What is 'Baiting' in cybersecurity?",
        "options": ["Fishing", "Leaving a malware-infected USB drive in a parking lot hoping someone plugs it into their computer", "Sending a spam email", "Hacking a router"]
      },
      {
        "answerIndex": 2,
        "question": "A website popup says you won a free iPhone, you just need to pay RM5 for shipping via credit card.",
        "options": ["Pay the RM5, it's a great deal", "Ask them to mail it for free", "It is an advance-fee fraud designed to steal your credit card details", "Give them your bank account number instead"]
      },
      {
        "answerIndex": 3,
        "question": "How can a Password Manager protect you from phishing?",
        "options": ["It creates a firewall", "It deletes spam emails", "It blocks popups", "It will refuse to autofill your password if the URL doesn't perfectly match the real website, even if it looks identical to you"]
      },
      {
        "answerIndex": 0,
        "question": "You click a link in an email and a file ending in '.exe' or '.scr' automatically downloads. You should:",
        "options": ["Immediately delete the file without opening it and run an antivirus scan", "Open it to see what it is", "Send it to a friend", "Rename it to a .pdf"]
      },
      {
        "answerIndex": 1,
        "question": "A Facebook friend sends a message: 'Is this you in this video?! [Link]'.",
        "options": ["Click it, you might be famous", "Their account was hacked; the link leads to a fake Facebook login page to steal your credentials", "Like the message", "Share it on your timeline"]
      },
      {
        "answerIndex": 2,
        "question": "What is MFA (Multi-Factor Authentication) Fatigue / Prompt Bombing?",
        "options": ["Getting tired of passwords", "A broken authenticator app", "Hackers spamming your phone with dozens of 2FA approval requests until you accidentally hit 'Approve' out of annoyance", "A slow SMS delivery"]
      },
      {
        "answerIndex": 3,
        "question": "You get a call from 'Bank Negara Malaysia' saying your account is involved in money laundering.",
        "options": ["Transfer your money to the 'safe account' they provide", "Give them your IC number", "Argue with them", "Hang up. Bank Negara does NOT call individuals about freezing accounts. It is a Macau Scam."]
      },
      {
        "answerIndex": 0,
        "question": "Why should you be cautious of shortened URLs (like bit.ly or tinyurl.com) in unexpected emails?",
        "options": ["They hide the true destination of the link, which could be a phishing site or malware download", "They look unprofessional", "They expire too quickly", "They are blocked by Google"]
      },
      {
        "answerIndex": 1,
        "question": "An email asks you to login to Google Drive to view a shared 'Bonus_Structure.pdf'. The login page looks slightly blurry.",
        "options": ["Log in to see your bonus", "It is a credential harvesting page. Check the URL bar, it likely does not say accounts.google.com", "Refresh the page to fix the blur", "Enter a fake password first"]
      },
      {
        "answerIndex": 2,
        "question": "If you accidentally click a phishing link and enter your password, what is the IMMEDIATE first step?",
        "options": ["Wait and see what happens", "Turn off your computer", "Go directly to the real website, change your password, and ensure 2FA is active", "Delete the phishing email"]
      },
      {
        "answerIndex": 3,
        "question": "A scammer calls you, already knowing your name, address, and the last 4 digits of your credit card. Does this mean they are legitimate?",
        "options": ["Yes, only banks have that info", "Yes, they must be the police", "Only if they know your birthday too", "No, this data was likely bought on the dark web from a previous corporate data breach to make the scam convincing"]
      },
      {
        "answerIndex": 0,
        "question": "What is 'Browser Credential Harvesting'?",
        "options": ["Malware that specifically targets and steals the passwords you told your web browser to 'save for later'", "Saving passwords in Chrome", "A new web browser", "Clearing your cookies"]
      },
      {
        "answerIndex": 1,
        "question": "An email from 'PayPal' threatens to permanently suspend your account in 24 hours if you don't click the link.",
        "options": ["You should click it to save your account", "This relies on the 'Urgency/Fear' tactic to make you act without thinking", "It is a standard security protocol", "PayPal is shutting down"]
      },
      {
        "answerIndex": 2,
        "question": "What is the danger of logging into your bank on free Public Wi-Fi at a cafe?",
        "options": ["The internet is too slow", "The cafe owner will see your balance", "Hackers on the same network can use packet sniffing or fake hotspots to intercept your unencrypted data", "Your battery will drain faster"]
      },
      {
        "answerIndex": 3,
        "question": "You get an email receipt for a \$500 computer you never bought, with a phone number to call for 'Customer Support' to cancel the order.",
        "options": ["Call the number immediately to cancel", "Reply to the email", "Forward it to the store", "It is a refund scam; calling the number connects you to a fake call center that will try to access your PC"]
      },
      {
        "answerIndex": 0,
        "question": "Why do phishing emails sometimes ask you to call a phone number instead of clicking a link?",
        "options": ["To bypass email security filters that scan for malicious URLs; the human on the phone acts as the phishing vector", "Links are too hard to make", "Phone calls are cheaper", "It is more personal"]
      },
      {
        "answerIndex": 1,
        "question": "What does a 'Tech Support Scam' usually look like?",
        "options": ["A real Microsoft technician visiting your house", "A popup or phone call claiming your PC is infected, demanding remote access (AnyDesk/TeamViewer) and payment to 'fix' it", "A free software upgrade", "A broken keyboard"]
      },
      {
        "answerIndex": 2,
        "question": "A charity emails you asking for donations in Bitcoin for disaster relief.",
        "options": ["Donate immediately", "Ask them for a receipt", "Extremely suspicious; legitimate charities rarely solicit untraceable cryptocurrency donations via cold emails", "Forward it to your friends"]
      },
      {
        "answerIndex": 3,
        "question": "How can you tell if an email address is spoofed?",
        "options": ["It breaks your browser", "It has bad grammar", "It doesn't have a signature", "Click the sender's name to view the actual email address, which won't match the company domain"]
      },
      {
        "answerIndex": 0,
        "question": "A scammer convinces you to install 'AnyDesk' on your computer to help process a refund. What are they actually doing?",
        "options": ["Gaining total remote control of your computer to log into your bank or steal files while the screen goes black", "Updating your software", "Installing an antivirus", "Fixing your internet connection"]
      },
      {
        "answerIndex": 1,
        "question": "What is the best defense against Adversary-in-the-Middle (AitM) phishing?",
        "options": ["Changing passwords weekly", "Using hardware security keys (like YubiKey or Passkeys) which cannot be intercepted by proxy sites", "Using a longer password", "Using an incognito window"]
      },
      {
        "answerIndex": 2,
        "question": "An email claims to have a video of you in a compromising situation and demands Bitcoin, but includes a password you actually used years ago as 'proof'.",
        "options": ["Pay the ransom immediately", "Reply to apologize", "It is an empty extortion scam (Sextortion) using an old password leaked in a public data breach; they have no video", "Click the link to watch the video"]
      },
      {
        "answerIndex": 3,
        "question": "Why do companies conduct 'Phishing Simulations' for their employees?",
        "options": ["To fire people", "To test internet speed", "To send out corporate memos", "To safely train employees to recognize red flags in a controlled environment before a real attack happens"]
      },
      {
        "answerIndex": 0,
        "question": "What should you do if you receive a suspicious email on your work computer?",
        "options": ["Forward it to your company's IT/Security department using the 'Report Phishing' button", "Delete it and forget it", "Reply and tell them to stop", "Click the link to investigate"]
      },
      {
        "answerIndex": 1,
        "question": "Which of these file extensions in an email attachment is the MOST dangerous to open?",
        "options": [".txt", ".vbs (Visual Basic Script)", ".jpg", ".mp4"]
      },
      {
        "answerIndex": 2,
        "question": "You see an ad on Google Search for 'Maybank Login', it is the top result and says 'Sponsored'. Is it safe?",
        "options": ["Yes, Google checks all ads", "Yes, sponsored links are secure", "Not always; scammers frequently buy malicious Google Ads that look identical to the real bank to appear at the top of search results", "Only if it has a star rating"]
      },
      {
        "answerIndex": 3,
        "question": "What is the principle of 'Zero Trust' in cybersecurity?",
        "options": ["Trusting nobody but your boss", "A type of firewall", "A software brand", "Never automatically trusting anything inside or outside the network; verify explicitly every time before granting access"]
      }
    ]
  };

  try {
    for (String chapterName in allQuizzes.keys) {
      await FirebaseFirestore.instance.collection('quizzes').doc(chapterName).set({
        'questions': allQuizzes[chapterName],
      });
      debugPrint("Uploaded: $chapterName");
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All Quizzes Successfully Uploaded!"), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    debugPrint("Failed to upload: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

// --- NEW DEV TOOL: EXPORT ALL QUIZZES ---
Future<void> fetchAndPrintAllQuizzes(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fetching database... Check your Debug Console!"), backgroundColor: Colors.blue),
    );

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('quizzes').get();
    Map<String, dynamic> allExportedQuizzes = {};

    for (var doc in querySnapshot.docs) {
      allExportedQuizzes[doc.id] = doc['questions'];
    }

    String prettyPrintJson = const JsonEncoder.withIndent('  ').convert(allExportedQuizzes);

    debugPrint("================= BEGIN DATABASE EXPORT =================");
    final pattern = RegExp('.{1,800}');
    pattern.allMatches(prettyPrintJson).forEach((match) => debugPrint(match.group(0)));
    debugPrint("================== END DATABASE EXPORT ==================");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Export successful! Scroll up in your console."), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    debugPrint("Error fetching quizzes: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch: $e"), backgroundColor: Colors.red),
      );
    }
  }
}