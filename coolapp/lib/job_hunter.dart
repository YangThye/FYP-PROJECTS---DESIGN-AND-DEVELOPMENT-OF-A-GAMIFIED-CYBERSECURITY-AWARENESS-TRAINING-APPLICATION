import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobHunterPage extends StatefulWidget {
  const JobHunterPage({super.key});

  @override
  State<JobHunterPage> createState() => _JobHunterPageState();
}

class _JobHunterPageState extends State<JobHunterPage> {
  final CardSwiperController controller = CardSwiperController();
  Key _swiperKey = UniqueKey();

  // --- EXPANDED LEVEL DATA ---
  final List<JobAd> jobs = [
    JobAd(
      companyName: "MegaTech Global (via WhatsApp)",
      role: "E-Commerce Affiliate",
      salary: "RM 500 - RM 1,000 / Day",
      description: "Easy work from home! Just click 'Like' on products. No experience needed. PM now!",
      isScam: true,
      reason: "Classic task scam. Real jobs don't pay RM1k/day for zero skills.",
    ),
    JobAd(
      companyName: "Petronas Digital",
      role: "Junior Data Analyst",
      salary: "RM 3,500 - RM 4,200",
      description: "Degree in CS/IT required. On-site role in KLCC. Please apply via official portal.",
      isScam: false,
      reason: "Realistic salary, clear requirements, official portal.",
    ),
    JobAd(
      companyName: "ShopeeExpress_Admin01",
      role: "Part-Time Order Processor",
      salary: "RM 8,000 / Month",
      description: "Process orders using your own bank account. Must pay RM100 training fee first.",
      isScam: true,
      reason: "Employers NEVER ask for a 'training fee' or use your personal bank account.",
    ),
    JobAd(
      companyName: "Infineon Technologies",
      role: "Information Technology Intern",
      salary: "RM 1,200 / Month",
      description: "Looking for motivated IT students. Official application via Infineon Careers portal. On-site role.",
      isScam: false,
      reason: "Clear role, realistic intern allowance, applied via the official careers portal.",
    ),
    JobAd(
      companyName: "LHDN Recruitment",
      role: "Tax Officer Assistant",
      salary: "RM 2,800",
      description: "Urgent hiring. Send your IC photo and Bank Password to check eligibility.",
      isScam: true,
      reason: "Government agencies will NEVER ask for your banking password.",
    ),
    JobAd(
      companyName: "Softinn Solutions",
      role: "Junior Web Developer",
      salary: "RM 3,000 - RM 3,500",
      description: "Must have experience with PHP, Bootstrap, and Cloud deployments. Submit portfolio and GitHub link.",
      isScam: false,
      reason: "Requires specific skills, realistic salary, requests a verifiable technical portfolio.",
    ),
    JobAd(
      companyName: "TikTok Global HR",
      role: "Video Liker Agent",
      salary: "RM 300 / Hour",
      description: "Work 2 hours a day liking videos. Salary paid daily to personal account. PM Admin on Telegram.",
      isScam: true,
      reason: "Massive pay for zero skill. Uses Telegram for hiring. Classic task scam.",
    ),
    JobAd(
      companyName: "Maybank",
      role: "Customer Service Exec",
      salary: "RM 3,000",
      description: "Shift work required. EPF & SOCSO provided. Walk-in interview at Menara Maybank.",
      isScam: false,
      reason: "Mention of EPF/SOCSO and a physical interview location are good signs.",
    ),
    JobAd(
      companyName: "ZUS Coffee",
      role: "Full-Time Barista",
      salary: "RM 1,500 + Allowances",
      description: "Join our fast-paced cafe team. EPF/SOCSO included. Shift rotations apply.",
      isScam: false,
      reason: "Standard retail/F&B job description with standard corporate benefits.",
    ),
    JobAd(
      companyName: "Shopee Merchants Group",
      role: "Rating Booster",
      salary: "Commission Based",
      description: "Help sellers boost ratings. Must deposit RM 500 into agent's account first to unlock high-tier tasks.",
      isScam: true,
      reason: "Any job requiring an upfront deposit to 'unlock' work is an advance-fee scam.",
    ),
    JobAd(
      companyName: "Multimedia University",
      role: "Research Assistant (Part-Time)",
      salary: "RM 800 / Month",
      description: "Assisting faculty with cybersecurity data collection. Open to current students.",
      isScam: false,
      reason: "University research roles are legitimate and properly target current students.",
    ),
    JobAd(
      companyName: "Crypto Mining Malaysia",
      role: "Passive Income Partner",
      salary: "RM 10,000 / Month",
      description: "Rent out your personal bank account to us for company transactions. Easy money, zero effort.",
      isScam: true,
      reason: "This is a Money Mule scam. You will be arrested for money laundering.",
    ),
  ];

  bool gameHasStarted = false;
  int score = 0;
  int timeLeft = 30;
  Timer? _timer;
  bool isGameOver = false;
  bool isSavingScore = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

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
              Text("Your mission is to review incoming job advertisements and filter out the scams.", style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.keyboard_double_arrow_left, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("SWIPE LEFT to REJECT a job if you spot red flags (e.g., upfront fees, insanely high pay).", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.keyboard_double_arrow_right, color: Colors.greenAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("SWIPE RIGHT to APPLY if the job looks legitimate and realistic.", style: TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text("+100 XP for correct decisions.\n-50 XP for falling for a scam or rejecting a real job.", style: TextStyle(color: Colors.white, fontSize: 14))),
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
      timeLeft = 30;
      isGameOver = false;
      jobs.shuffle();
      _swiperKey = UniqueKey();
    });
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        timer.cancel();
        handleGameOver("TIME'S UP!");
      }
    });
  }

  Future<void> handleGameOver(String title) async {
    setState(() {
      isGameOver = true;
      isSavingScore = true;
    });
    _timer?.cancel();
    ScaffoldMessenger.of(context).clearSnackBars();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final username = userDoc.data()?['username'] ?? "Anonymous Agent";

        final leaderboardRef = FirebaseFirestore.instance
            .collection('leaderboards')
            .doc('Job Hunter')
            .collection('scores')
            .doc(uid);

        final currentScoreDoc = await leaderboardRef.get();
        int previousScore = currentScoreDoc.data()?['score'] ?? 0;

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
      _showGameOverDialog(title);
    }
  }

  void _showGameOverDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Evaluation Complete.\nFinal Score: $score XP", style: const TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("TOP 5 HUNTERS", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 180,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('leaderboards')
                      .doc('Job Hunter')
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
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("EXIT", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => gameHasStarted = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text("REBOOT SYSTEM", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  bool _onSwipe(
      int previousIndex,
      int? currentIndex,
      CardSwiperDirection direction,
      ) {

    HapticFeedback.mediumImpact();
    JobAd currentJob = jobs[previousIndex];

    bool userApplied = direction == CardSwiperDirection.right;
    bool userRejected = direction == CardSwiperDirection.left;

    if (!userApplied && !userRejected) return false;

    bool isCorrectDecision = false;
    String feedbackTitle = "";
    Color feedbackColor = Colors.grey;

    if (userApplied) {
      if (currentJob.isScam) {
        isCorrectDecision = false;
        feedbackTitle = "❌ SCAMMED!";
        feedbackColor = Colors.redAccent;
        HapticFeedback.heavyImpact();
      } else {
        isCorrectDecision = true;
        feedbackTitle = "✅ GOOD HIRE!";
        feedbackColor = Colors.greenAccent;
      }
    } else if (userRejected) {
      if (currentJob.isScam) {
        isCorrectDecision = true;
        feedbackTitle = "✅ DODGED A BULLET!";
        feedbackColor = Colors.greenAccent;
      } else {
        isCorrectDecision = false;
        feedbackTitle = "❌ MISSED OPPORTUNITY!";
        feedbackColor = Colors.orangeAccent;
        HapticFeedback.heavyImpact();
      }
    }

    setState(() {
      if (isCorrectDecision) {
        score += 100;
      } else {
        score -= 50;
        if (score < 0) score = 0;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      feedbackTitle,
                      style: TextStyle(color: feedbackColor, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      isCorrectDecision ? "+100 XP" : "-50 XP",
                      style: TextStyle(color: isCorrectDecision ? Colors.yellow : Colors.red, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(currentJob.reason, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E2C).withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: feedbackColor.withValues(alpha: 0.5), width: 1)),
          duration: const Duration(seconds: 3),
        )
    );

    if (currentIndex == null) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) handleGameOver("MISSION ACCOMPLISHED");
      });
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.pop(context);
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("JOB HUNTER", style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.blueGrey, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$score XP", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Courier')),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: timeLeft <= 10 ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: timeLeft <= 10 ? Colors.redAccent : Colors.grey.withValues(alpha: 0.5))
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: timeLeft <= 10 ? Colors.redAccent : Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text("00:${timeLeft.toString().padLeft(2, '0')}",
                            style: TextStyle(color: timeLeft <= 10 ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. The Game Area
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_double_arrow_left, color: Colors.redAccent),
                        Text(" REJECT (Scam)", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        SizedBox(width: 30),
                        Text("APPLY (Legit) ", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        Icon(Icons.keyboard_double_arrow_right, color: Colors.greenAccent),
                      ],
                    ),
                  ),

                  Expanded(
                    child: CardSwiper(
                      key: _swiperKey,
                      controller: controller,
                      cardsCount: jobs.length,
                      onSwipe: _onSwipe,
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                      numberOfCardsDisplayed: jobs.length > 3 ? 3 : jobs.length,
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.all(24.0),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        // --- THE FIX: Removed SizedBox.shrink()! ---
                        // Cards now load normally in the background to prevent sizing bugs.

                        final job = jobs[index];

                        double rejectOpacity = (percentThresholdX < 0) ? (percentThresholdX.abs() / 100).clamp(0.0, 1.0) : 0.0;
                        double applyOpacity = (percentThresholdX > 0) ? (percentThresholdX / 100).clamp(0.0, 1.0) : 0.0;

                        return Stack(
                          children: [
                            _buildJobCard(job),

                            if (rejectOpacity > 0)
                              Positioned(
                                top: 40,
                                right: 40,
                                child: Transform.rotate(
                                  angle: 0.2,
                                  child: Opacity(
                                    opacity: rejectOpacity,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red, width: 4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text("REJECT", style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    ),
                                  ),
                                ),
                              ),

                            if (applyOpacity > 0)
                              Positioned(
                                top: 40,
                                left: 40,
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Opacity(
                                    opacity: applyOpacity,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.green, width: 4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text("APPLY", style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 2. Start Screen Overlay
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
                              color: Colors.cyanAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.cyanAccent, width: 2)
                          ),
                          child: const Icon(Icons.person_search, size: 60, color: Colors.cyanAccent),
                        ),
                        const SizedBox(height: 24),
                        const Text("INCOMING JOB OFFERS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            children: [
                              Text("👈 Swipe Left to REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 8),
                              Text("Swipe Right to APPLY 👉", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
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
                          child: const Text("START MISSION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
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

              // 3. Uploading Score Overlay
              if (isSavingScore)
                Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.cyanAccent),
                        SizedBox(height: 16),
                        Text("Uploading Score to Global Network...", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobAd job) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                  radius: 25,
                  child: Text(job.companyName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 20)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Posted 2h ago", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.role, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5))),
                    child: Text(job.salary, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                  const SizedBox(height: 24),
                  const Text("Job Description", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(job.description, style: TextStyle(color: Colors.grey[300], fontSize: 16, height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JobAd {
  final String companyName;
  final String role;
  final String salary;
  final String description;
  final bool isScam;
  final String reason;

  JobAd({
    required this.companyName,
    required this.role,
    required this.salary,
    required this.description,
    required this.isScam,
    required this.reason,
  });
}