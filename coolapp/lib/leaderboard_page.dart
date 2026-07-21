import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Changed from 4 to 3
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
          toolbarHeight: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 12.0, bottom: 12.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.only(right: 2.0),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                ),
              ),
            ),
          ),
          leadingWidth: 65,
          title: const Text(
              "GLOBAL LEADERBOARDS",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: "Job Hunter"),
              Tab(text: "Phish Shooter"),
              Tab(text: "Glitch Hunter"),
              // Removed Cyber Snake Tab
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardList(gameName: "Job Hunter", scoreSuffix: "XP", accentColor: Colors.teal),
            _LeaderboardList(gameName: "Phish Shooter", scoreSuffix: "XP", accentColor: Colors.blue),
            _LeaderboardList(gameName: "Glitch Hunter", scoreSuffix: "XP", accentColor: Colors.purple),
            // Removed Cyber Snake List
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE LEADERBOARD LIST WIDGET ---
class _LeaderboardList extends StatelessWidget {
  final String gameName;
  final String scoreSuffix;
  final Color accentColor;

  const _LeaderboardList({
    required this.gameName,
    required this.scoreSuffix,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Fetch top 10 players for this specific game
      stream: FirebaseFirestore.instance
          .collection('leaderboards')
          .doc(gameName)
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data", style: TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No scores logged yet.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Be the first to claim #1!", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;

            // Identify the Top 3
            bool isFirst = index == 0;
            bool isSecond = index == 1;
            bool isThird = index == 2;
            bool isPodium = isFirst || isSecond || isThird;

            // --- GOLD, SILVER, BRONZE STYLING ---
            Color rankColor;
            Color bgColor;
            if (isFirst) {
              rankColor = Colors.amber.shade500; // Gold
              bgColor = Colors.amber.withValues(alpha: 0.15);
            } else if (isSecond) {
              rankColor = Colors.blueGrey.shade400; // Silver
              bgColor = Colors.blueGrey.withValues(alpha: 0.15);
            } else if (isThird) {
              rankColor = Colors.brown.shade400; // Bronze
              bgColor = Colors.brown.withValues(alpha: 0.15);
            } else {
              rankColor = Colors.grey.shade400; // Standard
              bgColor = Colors.grey.withValues(alpha: 0.1);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isPodium ? rankColor.withValues(alpha: 0.5) : Colors.transparent,
                    width: isPodium ? 2 : 0
                ),
                boxShadow: [
                  BoxShadow(
                      color: isFirst ? rankColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10)
                  ),
                ],
              ),
              child: Row(
                children: [
                  // --- RANK BADGE (Circle Avatar) ---
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor, width: 2),
                    ),
                    child: Center(
                      child: isFirst
                          ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 26) // #1 Gets a trophy icon!
                          : Text(
                        "#${index + 1}",
                        style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // --- USERNAME ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['username'] ?? "Unknown",
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isFirst)
                          Text("Reigning Champion", style: TextStyle(color: Colors.amber.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // --- SCORE (NOW BOLD NO BORDER) ---
                  Text(
                      "${data['score']} $scoreSuffix",
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontFamily: 'Courier'
                      )
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}