import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class PreliminaryCheckPage extends StatefulWidget {
  const PreliminaryCheckPage({super.key});

  @override
  State<PreliminaryCheckPage> createState() => _PreliminaryCheckPageState();
}

class _PreliminaryCheckPageState extends State<PreliminaryCheckPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final Map<int, int> _selectedAnswers = {};

  final List<Map<String, dynamic>> _baselineQuestions = [
    {
      "question": "A recruiter on Telegram offers you a job 'optimizing app ratings' by depositing money into a portal to unlock higher-tier tasks. What is the precise name of this scam?",
      "options": ["Affiliate Marketing", "Task/Mission Scam", "Pyramid Scheme", "Dropshipping"],
      "answerIndex": 1
    },
    {
      "question": "You enter your password on a fake bank login page and complete the SMS OTP prompt, but your account is still hacked. How did they bypass your 2FA?",
      "options": ["They cloned your SIM card", "They used a proxy to intercept your session cookie", "They brute-forced the code", "They hacked your Bluetooth"],
      "answerIndex": 1
    },
    {
      "question": "During a live video call, you suspect the CEO on the screen is an AI deepfake. What is the most effective technical challenge?",
      "options": ["Ask a personal question only they would know", "Ask them to quickly pass their hand directly in front of their face", "Ask them to hold up a newspaper", "Ask them to solve a math problem"],
      "answerIndex": 1
    },
    {
      "question": "You receive an urgent email instructing you to wire funds. The email address exactly matches your boss's, but their account was not hacked. What technique was used?",
      "options": ["Email Spoofing", "DNS Hijacking", "SQL Injection", "Cross-Site Scripting"],
      "answerIndex": 0
    },
    {
      "question": "You accept a job where you receive funds into your personal bank account and immediately transfer them to a crypto wallet. What is your actual role?",
      "options": ["Payment Gateway Provider", "Escrow Agent", "Money Mule", "Forensic Accountant"],
      "answerIndex": 2
    }
  ];

  Future<void> _completeInitialization() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email ?? "Agent";

      if (uid != null) {
        int score = 0;
        for (int i = 0; i < _baselineQuestions.length; i++) {
          if (_selectedAnswers[i] == _baselineQuestions[i]["answerIndex"]) {
            score++;
          }
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'baseline_score': score,
          'baseline_total': _baselineQuestions.length,
          'onboarding_complete': true,
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(username: email)),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    int totalPages = _baselineQuestions.length;

    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeInitialization();
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = _baselineQuestions.length;
    bool canProceed = _selectedAnswers.containsKey(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Tightened screen padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- PROGRESS INDICATOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: () {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black54, size: 20),
                    )
                  else
                    const SizedBox(width: 20),

                  Text(
                    "Step ${_currentPage + 1} of $totalPages",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- INTRO HEADER (Only on first question) ---
              if (_currentPage == 0) ...[
                const Text(
                  "Agent Initialization",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5), // Smaller font
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's assess your knowledge to calibrate your starting rank.",
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey[600], height: 1.4), // Smaller font
                ),
                const SizedBox(height: 16), // Tighter spacing
              ],

              // --- DYNAMIC PAGE CONTENT ---
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: _baselineQuestions.asMap().entries.map((entry) {
                    return _buildQuizPage(entry.key, entry.value);
                  }).toList(),
                ),
              ),

              // --- BOTTOM ACTION BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (canProceed && !_isLoading) ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                      _currentPage == totalPages - 1 ? "Finish Initialization" : "Next",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: canProceed ? Colors.white : Colors.grey.shade500)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGET: BASELINE QUIZ ---
  Widget _buildQuizPage(int questionIndex, Map<String, dynamic> questionData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Tighter badge
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text("BASELINE TEST", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 16), // Tighter spacing
        Text(
          questionData["question"],
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.3), // Slightly smaller question font
        ),
        const SizedBox(height: 20), // Tighter spacing
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: (questionData["options"] as List).length,
            itemBuilder: (context, optionIndex) {
              final optionText = questionData["options"][optionIndex];
              final isSelected = _selectedAnswers[questionIndex] == optionIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedAnswers[questionIndex] = optionIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12), // Reduced margin
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Reduced internal padding
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.0
                    ),
                    boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              optionText,
                              style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.blueAccent : Colors.black87) // Slightly smaller text
                          )
                      ),
                      const SizedBox(width: 8),
                      if (isSelected) const Icon(Icons.radio_button_checked, color: Colors.blueAccent, size: 22),
                      if (!isSelected) const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}