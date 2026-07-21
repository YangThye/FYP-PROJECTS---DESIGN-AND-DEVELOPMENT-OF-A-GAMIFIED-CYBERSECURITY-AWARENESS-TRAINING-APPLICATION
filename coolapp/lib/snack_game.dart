import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const CyberSnakeApp());
}

// --- Helper Class for Game Items ---
enum ItemType { number, symbol, threat }

class GameItem {
  int position;
  String content; // The text to show (e.g., "5", "@", "☠️")
  ItemType type;
  int points;
  Color color;
  DateTime creationTime;

  GameItem({
    required this.position,
    required this.content,
    required this.type,
    required this.points,
    required this.color,
    required this.creationTime,
  });
}

class CyberSnakeApp extends StatelessWidget {
  const CyberSnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFC2),
          secondary: Color(0xFF00E5FF),
        ),
      ),
      home: const SnakeGamePage(),
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  // --- Game Settings ---
  static const int rowCount = 20;
  static const int columnCount = 20;
  static const int totalSquares = rowCount * columnCount;
  static const int gameSpeed = 300;

  // --- Game State ---
  List<int> snakePos = [45, 65, 85];
  String direction = 'down';
  bool gameHasStarted = false;
  Timer? _timer;
  int score = 0;

  // --- NEW: List to hold multiple items ---
  List<GameItem> activeItems = [];

  // Characters for generation
  final List<String> symbols = ['@', '#', '\$', '%', '&', '!', '?'];
  final List<String> numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  // --- Logic: Start Game ---
  void startGame() {
    setState(() {
      gameHasStarted = true;
      snakePos = [45, 65, 85];
      direction = 'down';
      score = 0;
      activeItems.clear();
      // Spawn 3 initial items
      spawnRandomItem();
      spawnRandomItem();
      spawnRandomItem();
    });

    _timer = Timer.periodic(const Duration(milliseconds: gameSpeed), (timer) {
      updateSnake();
    });
  }

  void updateSnake() {
    setState(() {
      // --- NEW: Check for Expired Skulls ---
      final now = DateTime.now();

      // 1. Find the index of the first expired skull
      // We look for a THREAT that is older than 10 seconds
      int expiredIndex = activeItems.indexWhere((item) =>
      item.type == ItemType.threat &&
          now.difference(item.creationTime).inSeconds >= 10
      );

      // 2. If we found one, remove it and spawn a replacement
      if (expiredIndex != -1) {
        activeItems.removeAt(expiredIndex); // Remove the old skull
        spawnRandomItem(); // Add a new random item immediately
      }
      // -------------------------------------

      // 3. Calculate new head position
      int newHead = snakePos.last;
      if (direction == 'down') {
        newHead += columnCount;
      } else if (direction == 'up') {
        newHead -= columnCount;
      } else if (direction == 'left') {
        newHead -= 1;
      } else if (direction == 'right') {
        newHead += 1;
      }

      // 4. Check Wall/Self Collision
      if (checkCollision(newHead)) {
        gameOver("WALL COLLISION");
        return;
      }

      // 5. Check Item Collision
      int itemIndex = activeItems.indexWhere((item) => item.position == newHead);

      if (itemIndex != -1) {
        GameItem eatenItem = activeItems[itemIndex];

        if (eatenItem.type == ItemType.threat) {
          gameOver("PHISHING ATTACK DETECTED");
          return;
        } else {
          score += eatenItem.points;
          snakePos.add(newHead);
          activeItems.removeAt(itemIndex);
          spawnRandomItem();
        }
      } else {
        snakePos.add(newHead);
        snakePos.removeAt(0);
      }
    });
  }

  // --- Logic: Collision Detection ---
  bool checkCollision(int pos) {
    if (pos < 0 || pos >= totalSquares) return true;
    if (direction == 'right' && pos % columnCount == 0) return true;
    if (direction == 'left' && (pos + 1) % columnCount == 0) return true;
    if (snakePos.contains(pos)) return true;
    return false;
  }

  // --- Logic: Spawn Items ---
  void spawnRandomItem() {
    Random rand = Random();
    int pos = rand.nextInt(totalSquares);

    // Prevent spawning on snake or on top of another item
    while (snakePos.contains(pos) || activeItems.any((item) => item.position == pos)) {
      pos = rand.nextInt(totalSquares);
    }

    // Determine Type (20% Threat, 40% Number, 40% Symbol)
    int typeRoll = rand.nextInt(100);
    GameItem newItem;

    DateTime now = DateTime.now();

    if (typeRoll < 20) {
      // THREAT (Red Skull)
      newItem = GameItem(
        position: pos,
        content: "☠️",
        type: ItemType.threat,
        points: -2,
        color: Colors.redAccent,
        creationTime: now,
      );
    } else if (typeRoll < 60) {
      // NUMBER (+1 Point)
      newItem = GameItem(
        position: pos,
        content: numbers[rand.nextInt(numbers.length)],
        type: ItemType.number,
        points: 1,
        color: Colors.blueAccent,
        creationTime: now,
      );
    } else {
      // SYMBOL (+3 Points)
      newItem = GameItem(
        position: pos,
        content: symbols[rand.nextInt(symbols.length)],
        type: ItemType.symbol,
        points: 3,
        color: Colors.orangeAccent,
        creationTime: now,
      );
    }

    setState(() {
      activeItems.add(newItem);
    });
  }

  void gameOver(String reason) {
    _timer?.cancel();
    setState(() {
      gameHasStarted = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(reason == "PHISHING ATTACK DETECTED" ? "INFECTED!" : "HACKED!",
              style: const TextStyle(color: Colors.redAccent)),
          content: Text(
            "Cause: $reason\nFinal Score: $score\nPass Length: ${snakePos.length}",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startGame();
              },
              child: const Text("RETRY MISSION", style: TextStyle(color: Color(0xFF00FFC2))),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- THE HUD ---
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: const Color(0xFF1E1E2C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CYBER SNAKE",
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                    Text(
                        "SCORE: $score", // Changed to show Score
                        style: const TextStyle(color: Color(0xFF00FFC2), fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("SECURITY",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(
                        "${snakePos.length} BITS", // Changed to simulate bits
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- THE GAME GRID ---
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (direction != 'up' && details.delta.dy > 0) {
                  direction = 'down';
                } else if (direction != 'down' && details.delta.dy < 0) {
                  direction = 'up';
                }
              },
              onHorizontalDragUpdate: (details) {
                if (direction != 'left' && details.delta.dx > 0) {
                  direction = 'right';
                } else if (direction != 'right' && details.delta.dx < 0) {
                  direction = 'left';
                }
              },
              child: Container(
                color: Colors.black,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalSquares,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                  ),
                  itemBuilder: (context, index) {

                    // 1. Is this the snake?
                    if (snakePos.contains(index)) {
                      bool isHead = (index == snakePos.last);
                      return Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            color: isHead ? Colors.white : const Color(0xFF00FFC2),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              if (isHead)
                                const BoxShadow(color: Color(0xFF00FFC2), blurRadius: 5)
                            ]
                        ),
                      );
                    }

                    // 2. Is this an Item? (Food or Threat)
                    // We check if the current grid index exists in our activeItems list
                    final itemIndex = activeItems.indexWhere((item) => item.position == index);

                    if (itemIndex != -1) {
                      final item = activeItems[itemIndex];
                      return Center(
                          child: Text(
                              item.content,
                              style: TextStyle(
                                  color: item.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  shadows: [
                                    BoxShadow(color: item.color, blurRadius: 3)
                                  ]
                              )
                          )
                      );
                    }

                    // 3. Empty Grid
                    return Container(
                      margin: const EdgeInsets.all(1),
                      color: const Color(0xFF111111),
                    );
                  },
                ),
              ),
            ),
          ),

          // --- START BUTTON ---
          if (!gameHasStarted)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFC2),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: startGame,
                  child: const Text("INITIATE PROTOCOL", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
        ],
      ),
    );
  }
}