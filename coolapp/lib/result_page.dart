import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> reviewData;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.reviewData,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage to show different messages
    double percentage = totalQuestions == 0 ? 0 : score / totalQuestions;
    String titleText = "Great Job!";
    Color headerColor = Colors.blueAccent;

    if (percentage == 1.0) {
      titleText = "Perfect Score! 🏆";
      headerColor = Colors.amber.shade600;
    } else if (percentage < 0.5) {
      titleText = "Keep Practicing! 📚";
      headerColor = Colors.orangeAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- PREMIUM HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: headerColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  // Big Score Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(text: "$score\n", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: headerColor, height: 1.0)),
                            TextSpan(text: "out of $totalQuestions", style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- REVIEW SECTION ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Review Your Answers",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Scrollable List of Answers
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                itemCount: reviewData.length,
                itemBuilder: (context, index) {
                  final data = reviewData[index];
                  final bool isCorrect = data["isCorrect"];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data["question"],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                        // User's Answer
                        Text(
                          "Your Answer: ${data["selected"]}",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isCorrect ? Colors.green.shade700 : Colors.red.shade700),
                        ),

                        // Show correct answer if they got it wrong
                        if (!isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              "Correct Answer: ${data["correct"]}",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade700),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- DONE BUTTON ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Pops back to the Academy/Arcade
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}