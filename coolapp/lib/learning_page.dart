import 'package:flutter/material.dart';
import 'video_player_page.dart';
import 'quiz_page.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 130),
          physics: const BouncingScrollPhysics(),
          children: [
            // --- THE SEAMLESS HEADER ---
            const Text(
              "Cyber Academy",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Watch, learn, and unlock new missions.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            // --- VIDEO LIBRARY ---

            // 1. Job Scams Video
            _buildVideoCard(
              title: "Job Scams",
              subtitle: "Animated stickman guide to spotting fake recruiters.",
              duration: "4:20",
              thumbnailColor: Colors.redAccent,
              icon: Icons.work_off,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoPlayerPage(
                      videoTitle: "Job Scams",
                      videoDescription: "In this module, you will learn the top 3 red flags of fake recruitment offers in Malaysia, including upfront payments and suspicious WhatsApp interviews.",
                      videoUrl: 'assets/videos/Job_Scam.mp4',
                      // --- FIX: Added questionLimit: 10 ---
                      linkedQuizPage: QuizPage(chapterName: "Job Scams Assessment", questionLimit: 10),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Phishing Video
            _buildVideoCard(
              title: "Phishing",
              subtitle: "Don't take the bait. Analyze real-world phishing emails.",
              duration: "4:43",
              thumbnailColor: Colors.orange,
              icon: Icons.phishing,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoPlayerPage(
                      videoTitle: "Phishing",
                      videoDescription: "Analyze real-world phishing emails and malicious links to avoid giving away your credentials to fake websites.",
                      videoUrl: 'assets/videos/Online_Investment_Scam.mp4',
                      // --- FIX: Added questionLimit: 10 ---
                      linkedQuizPage: QuizPage(chapterName: "Phishing Assessment", questionLimit: 10),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 3. Deepfakes Video
            _buildVideoCard(
              title: "Deepfakes",
              subtitle: "How to identify AI-generated video and audio scams.",
              duration: "3:47",
              thumbnailColor: Colors.purple,
              icon: Icons.face_retouching_off,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoPlayerPage(
                      videoTitle: "Deepfakes",
                      videoDescription: "Learn to identify unnatural blinking, audio glitches, and other common deepfake flaws.",
                      videoUrl: 'assets/videos/Deepfake.mp4',
                      // --- FIX: Added questionLimit: 10 ---
                      linkedQuizPage: QuizPage(chapterName: "Deepfake Assessment", questionLimit: 10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: VIDEO CARD UI ---
  Widget _buildVideoCard({
    required String title,
    required String subtitle,
    required String duration,
    required Color thumbnailColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: thumbnailColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: thumbnailColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(child: Icon(icon, size: 60, color: thumbnailColor)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Text(duration, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[800])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}