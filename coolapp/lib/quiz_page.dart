import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'result_page.dart';

class AnimatedProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;

  const AnimatedProgressBar({super.key, required this.currentQuestion, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    double progress = totalQuestions == 0 ? 0 : currentQuestion / totalQuestions;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 12,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String chapterName;
  final int? questionLimit;
  final bool isArcadeMode;

  const QuizPage({
    super.key,
    required this.chapterName,
    this.questionLimit,
    this.isArcadeMode = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool isLoading = true;
  bool isSaving = false;

  int currentQuestion = 0;
  int score = 0;
  bool answered = false;
  int? selectedAnswer;

  List<Map<String, dynamic>> review = [];
  List<Map<String, dynamic>> questions = [];

  final Map<String, List<Map<String, dynamic>>> fallbackDatabase = {
    "Job Scams Assessment": [
      {"question": "A recruiter messages you on WhatsApp offering RM500/day just to 'like' YouTube videos. What is this?", "options": ["A legitimate marketing job", "A classic task scam", "A government initiative", "A freelance gig"], "answerIndex": 1},
      {"question": "The 'employer' says you are hired, but you must pay RM150 for a 'training kit' first. What should you do?", "options": ["Pay the fee quickly to secure the job", "Ask if you can pay in installments", "Block the number immediately", "Give them your bank login details instead"], "answerIndex": 2},
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.chapterName == "Daily Mix") {
      _generateDailyMix();
    } else {
      _fetchQuestionsFromDatabase();
    }
  }

  // --- 1A. NORMAL QUIZ LOGIC ---
  Future<void> _fetchQuestionsFromDatabase() async {
    try {
      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.chapterName)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (quizDoc.exists) {
        List<dynamic> dbQuestions = quizDoc.get('questions');
        List<Map<String, dynamic>> allModuleQuestions = List<Map<String, dynamic>>.from(dbQuestions);

        // Shuffle so it's a random mix every time
        allModuleQuestions.shuffle();

        setState(() {
          if (widget.questionLimit != null) {
            questions = allModuleQuestions.take(widget.questionLimit!).toList();
          } else {
            questions = allModuleQuestions;
          }
          isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (e) {
      debugPrint("Firebase Error or Timeout: $e");
      _useFallbackData();
    }
  }

  // --- 1B. DAILY MIX SHUFFLE LOGIC ---
  Future<void> _generateDailyMix() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
      List<Map<String, dynamic>> allQuestionsPool = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('questions')) {
          List<dynamic> qList = data['questions'];
          for (var q in qList) {
            allQuestionsPool.add(q as Map<String, dynamic>);
          }
        }
      }

      final now = DateTime.now();
      int todaySeed = (now.year * 10000) + (now.month * 100) + now.day;
      var random = Random(todaySeed);
      allQuestionsPool.shuffle(random);

      setState(() {
        questions = allQuestionsPool.take(5).toList();
        isLoading = false;
      });

    } catch (e) {
      debugPrint("Error loading daily mix: $e");
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    List<Map<String, dynamic>> fallback = fallbackDatabase[widget.chapterName] ?? fallbackDatabase["Job Scams Assessment"]!;

    fallback.shuffle();

    setState(() {
      if (widget.questionLimit != null) {
        questions = fallback.take(widget.questionLimit!).toList();
      } else {
        questions = fallback;
      }
      isLoading = false;
    });
  }

  void selectAnswer(int index) {
    if (answered) return;
    final correctAnswer = questions[currentQuestion]["answerIndex"] as int;

    setState(() {
      selectedAnswer = index;
      answered = true;
      review.add({
        "question": questions[currentQuestion]["question"],
        "selected": questions[currentQuestion]["options"][index],
        "correct": questions[currentQuestion]["options"][correctAnswer],
        "isCorrect": index == correctAnswer,
      });
      if (selectedAnswer == correctAnswer) score++;
    });
  }

  void nextQuestion() async {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      await _saveScoreToDatabase();
    }
  }

  // --- 2. THE NEW SMART SAVE LOGIC ---
  Future<void> _saveScoreToDatabase() async {
    setState(() { isSaving = true; });

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        if (widget.chapterName == "Daily Mix") {
          // Just increment the counter, no score saved for Daily Mix
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'quizzes_completed': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } else if (widget.isArcadeMode) {
          // ARCADE MODE: Saves to 'arcade_scores' to protect the main XP / Badges
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'quizzes_completed': FieldValue.increment(1),
            'arcade_scores': {
              widget.chapterName: score,
            }
          }, SetOptions(merge: true));
        } else {
          // LEARNING MODE: Saves to the official 'quiz_scores' for badges and ranks
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'quizzes_completed': FieldValue.increment(1),
            'quiz_scores': {
              widget.chapterName: score,
            }
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Error saving score: $e");
    }

    if (!mounted) return;

    setState(() { isSaving = false; });

    if (context.mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ResultPage(
                score: score,
                totalQuestions: questions.length,
                reviewData: review,
              )
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapterName)),
        body: const Center(child: Text("No questions found.")),
      );
    }

    final question = questions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN BACKGROUND CONTENT ---
            Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey, size: 28)),
                      const SizedBox(width: 16),
                      Expanded(child: AnimatedProgressBar(currentQuestion: currentQuestion + (answered ? 1 : 0), totalQuestions: questions.length)),
                      const SizedBox(width: 16),
                      Text("${currentQuestion + 1}/${questions.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
                    ],
                  ),
                ),

                // QUESTION AREA
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: widget.chapterName == "Daily Mix" ? Colors.orange.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                              widget.chapterName.toUpperCase(),
                              style: TextStyle(
                                  color: widget.chapterName == "Daily Mix" ? Colors.orange : Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2
                              )
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(question["question"] as String, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.3)),
                        const SizedBox(height: 32),
                        ...(question["options"] as List<dynamic>).asMap().entries.map((entry) {
                          return _buildOptionCard(entry.key, entry.value.toString());
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- THE FLOATING, SLIDING BUTTON ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              bottom: answered ? 0 : -120,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, -5))
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedAnswer == questions[currentQuestion]["answerIndex"] ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      currentQuestion < questions.length - 1 ? "Continue" : "Save & Finish",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int idx, String optionText) {
    final correctAnswer = questions[currentQuestion]["answerIndex"] as int;
    bool isSelected = selectedAnswer == idx;
    bool isCorrect = idx == correctAnswer;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;

    if (answered) {
      if (isCorrect) {
        cardColor = Colors.green.shade50; borderColor = Colors.green; textColor = Colors.green.shade800; trailingIcon = Icons.check_circle; iconColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        cardColor = Colors.red.shade50; borderColor = Colors.red; textColor = Colors.red.shade800; trailingIcon = Icons.cancel; iconColor = Colors.red;
      } else {
        borderColor = Colors.grey.shade200; textColor = Colors.grey.shade500;
      }
    }

    return GestureDetector(
      onTap: answered ? null : () => selectAnswer(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected || (answered && isCorrect) ? 2.5 : 1.5),
          boxShadow: [if (!answered) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(child: Text(optionText, style: TextStyle(fontSize: 16, fontWeight: isSelected || (answered && isCorrect) ? FontWeight.bold : FontWeight.w500, color: textColor))),
            if (trailingIcon != null) Icon(trailingIcon, color: iconColor, size: 28),
          ],
        ),
      ),
    );
  }
}