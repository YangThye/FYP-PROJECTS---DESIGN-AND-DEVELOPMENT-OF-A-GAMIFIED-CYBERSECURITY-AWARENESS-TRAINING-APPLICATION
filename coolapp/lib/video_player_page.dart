import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoTitle;
  final String videoDescription;
  final String videoUrl;
  final Widget linkedQuizPage;

  const VideoPlayerPage({
    super.key,
    required this.videoTitle,
    required this.videoDescription,
    required this.videoUrl,
    required this.linkedQuizPage,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isVideoFinished = false;
  bool _isSaving = false;

  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      if (!_isVideoFinished && _controller.value.isInitialized) {
        final duration = _controller.value.duration;
        final position = _controller.value.position;

        // --- PRO-TIP FIX: 500ms safety buffer so the video always registers as complete! ---
        if (duration > Duration.zero && position >= duration - const Duration(milliseconds: 500)) {
          _markVideoAsCompleted();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seek(int seconds) {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition + Duration(seconds: seconds);

    if (targetPosition < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (targetPosition > _controller.value.duration) {
      _controller.seekTo(_controller.value.duration);
    } else {
      _controller.seekTo(targetPosition);
    }
  }

  Future<void> _loadUnlockState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final unlockedMap = data['unlocked_videos'] as Map<String, dynamic>? ?? {};

      if (unlockedMap[widget.videoTitle] == true && mounted) {
        setState(() {
          _isVideoFinished = true;
        });
      }
    }
  }

  Future<void> _markVideoAsCompleted() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'unlocked_videos': {
          widget.videoTitle: true
        }
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() {
      _isVideoFinished = true;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Module completed! Quiz unlocked.", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(controller: _controller),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- 1. CUSTOM HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.videoTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. THE REAL VIDEO PLAYER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: _controller.value.isInitialized ? _controller.value.aspectRatio : 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [

                            if (_controller.value.isInitialized)
                              VideoPlayer(_controller)
                            else
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.blueAccent),
                                  SizedBox(height: 12),
                                  Text("Decrypting Module...", style: TextStyle(color: Colors.white70)),
                                ],
                              ),

                            // --- THE INVISIBLE DOUBLE-TAP & MENU TOGGLE ZONES ---
                            if (_controller.value.isInitialized)
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onDoubleTap: () => _seek(-5),
                                        onTap: () {
                                          setState(() { _showControls = !_showControls; });
                                        },
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onDoubleTap: () => _seek(5),
                                        onTap: () {
                                          setState(() { _showControls = !_showControls; });
                                        },
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // --- VISIBLE CONTROLS OVERLAY ---
                            if (_controller.value.isInitialized)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: !_showControls && _controller.value.isPlaying,
                                  child: AnimatedOpacity(
                                    opacity: (_showControls || !_controller.value.isPlaying) ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() { _showControls = false; });
                                      },
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                                              iconSize: 40,
                                              onPressed: () => _seek(-5),
                                            ),
                                            const SizedBox(width: 15),

                                            // --- THE DYNAMIC PLAY/PAUSE BUTTON ---
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (_controller.value.isPlaying) {
                                                    _controller.pause();
                                                    _showControls = true;
                                                  } else {
                                                    _controller.play();
                                                    _showControls = false;
                                                  }
                                                });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                      _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                      color: Colors.white,
                                                      size: 60
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 15),
                                            IconButton(
                                              icon: const Icon(Icons.forward_5_rounded, color: Colors.white),
                                              iconSize: 40,
                                              onPressed: () => _seek(5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Full Screen Button
                            if (_controller.value.isInitialized)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: AnimatedOpacity(
                                  opacity: (_showControls || !_controller.value.isPlaying) ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: IgnorePointer(
                                    ignoring: !_showControls && _controller.value.isPlaying,
                                    child: GestureDetector(
                                      onTap: _openFullScreen,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Progress Indicator
                            if (_controller.value.isInitialized)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: Colors.blueAccent,
                                    bufferedColor: Colors.blueAccent.withValues(alpha: 0.3),
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- 3. VIDEO DETAILS & QUIZ CARD ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Module Overview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.videoDescription,
                      style: TextStyle(fontSize: 15, color: Colors.blueGrey[600], height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _isVideoFinished ? Colors.green.withValues(alpha: 0.3) : Colors.blueAccent.withValues(alpha: 0.1),
                            width: 2
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isVideoFinished ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                _isVideoFinished ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                color: _isVideoFinished ? Colors.green : Colors.grey,
                                size: 40
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isVideoFinished ? "Module Unlocked!" : "Quiz Locked",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isVideoFinished ? Colors.black87 : Colors.grey.shade600
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isVideoFinished
                                ? "You've finished the lesson. Ready to prove your skills?"
                                : "Watch the video entirely to unlock your assessment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isVideoFinished
                                  ? () {
                                _controller.pause();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => widget.linkedQuizPage),
                                );
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: Text(
                                _isVideoFinished ? "Take the Quiz" : "Watch Video First",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isVideoFinished ? Colors.white : Colors.grey.shade500
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// --- FULL SCREEN VIDEO WIDGET ---
// =====================================================================
class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPage({super.key, required this.controller});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _seek(int seconds) {
    final currentPosition = widget.controller.value.position;
    final targetPosition = currentPosition + Duration(seconds: seconds);

    if (targetPosition < Duration.zero) {
      widget.controller.seekTo(Duration.zero);
    } else if (targetPosition > widget.controller.value.duration) {
      widget.controller.seekTo(widget.controller.value.duration);
    } else {
      widget.controller.seekTo(targetPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
          ),

          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => _seek(-5),
                    onTap: () {
                      setState(() { _showControls = !_showControls; });
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => _seek(5),
                    onTap: () {
                      setState(() { _showControls = !_showControls; });
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showControls && widget.controller.value.isPlaying,
              child: AnimatedOpacity(
                opacity: (_showControls || !widget.controller.value.isPlaying) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() { _showControls = false; });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                          iconSize: 50,
                          onPressed: () => _seek(-5),
                        ),
                        const SizedBox(width: 40),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (widget.controller.value.isPlaying) {
                                widget.controller.pause();
                                _showControls = true;
                              } else {
                                widget.controller.play();
                                _showControls = false;
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                  widget.controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 70
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 40),
                        IconButton(
                          icon: const Icon(Icons.forward_5_rounded, color: Colors.white),
                          iconSize: 50,
                          onPressed: () => _seek(5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: (_showControls || !widget.controller.value.isPlaying) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls && widget.controller.value.isPlaying,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.blueAccent,
                bufferedColor: Colors.blueAccent.withValues(alpha: 0.3),
                backgroundColor: Colors.white24,
              ),
            ),
          )
        ],
      ),
    );
  }
}