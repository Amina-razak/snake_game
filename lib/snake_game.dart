import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({Key? key}) : super(key: key);

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

enum DIRECTION { top, left, right, bottom }

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  final AudioPlayer audioCache = AudioPlayer();
  List<int> snakePosition = [45, 65, 85, 105, 125];
  var snakeDirection = DIRECTION.bottom;
  int foodPosition = 15;
  int score = 0;
  int rowCount = 20;
  int colsCount = 20;
  Offset? initialPosition;
  late Timer _timer;
  bool _gameOverMusicPlayed = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void onPanStart(DragStartDetails details) {
    initialPosition = details.globalPosition;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (initialPosition == null) return;

    final dx = details.globalPosition.dx - initialPosition!.dx;
    final dy = details.globalPosition.dy - initialPosition!.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0 && snakeDirection != DIRECTION.left) {
        snakeDirection = DIRECTION.right;
      } else if (dx < 0 && snakeDirection != DIRECTION.right) {
        snakeDirection = DIRECTION.left;
      }
    } else {
      if (dy > 0 && snakeDirection != DIRECTION.top) {
        snakeDirection = DIRECTION.bottom;
      } else if (dy < 0 && snakeDirection != DIRECTION.bottom) {
        snakeDirection = DIRECTION.top;
      }
    }

    initialPosition = details.globalPosition;
  }

  startGame() {
    _gameOverMusicPlayed = false;
    snakePosition = [45, 65, 85, 105, 125];
    snakeDirection = DIRECTION.bottom;
    foodPosition = 15;
    score = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      updateGame();
    });
  }

  updateGame() {
    updateSnake();
    checkCollision();
    if (snakePosition.first == foodPosition) {
      generateFood();
      audioCache.play(AssetSource("eat.mp3"));
      setState(() {
        score++;
      });
    }
  }

  void checkCollision() {
    final head = snakePosition.last;

    // Check if the snake's head collides with its body (excluding the tail)
    for (int i = 0; i < snakePosition.length - 1; i++) {
      if (snakePosition[i] == head) {
        _timer.cancel();
        gameOver();
        break;
      }
    }
  }

  void gameOver() {
    setState(() {
      _timer.cancel();
      if (!_gameOverMusicPlayed) {
        audioCache.play(AssetSource("gameover.mp3"));
        _gameOverMusicPlayed = true;
      }
      gameoverAlert();
    });
  }

  void updateSnake() {
    setState(() {
      switch (snakeDirection) {
        case DIRECTION.top:
          if (snakePosition.last < 20) {
            snakePosition.add(snakePosition.last - 20 + 760);
          } else {
            snakePosition.add(snakePosition.last - 20);
          }
          break;
        case DIRECTION.bottom:
          if (snakePosition.last > 740) {
            snakePosition.add(snakePosition.last + 20 - 760);
          } else {
            snakePosition.add(snakePosition.last + 20);
          }
          break;
        case DIRECTION.left:
          if (snakePosition.last % 20 == 0) {
            snakePosition.add(snakePosition.last - 1 + 20);
          } else {
            snakePosition.add(snakePosition.last - 1);
          }
          break;
        case DIRECTION.right:
          if ((snakePosition.last + 1) % 20 == 0) {
            snakePosition.add(snakePosition.last + 1 - 20);
          } else {
            snakePosition.add(snakePosition.last + 1);
          }
          break;
      }

      // Check if the snake eats the food
      if (snakePosition.last == foodPosition) {
        generateFood();
        audioCache.play(AssetSource("eat.mp3"));
        score++; // Update score here
      } else {
        // If the snake doesn't eat food, remove the tail segment
        snakePosition.removeAt(0);
      }
    });
  }

  void generateFood() {
    Random random = Random();
    int newFoodPosition;
    do {
      newFoodPosition = random.nextInt(700);
    } while (snakePosition.contains(newFoodPosition));

    foodPosition = newFoodPosition;
    audioCache.play(AssetSource("eat.mp3"));
  }

  gameoverAlert() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.greenAccent.withOpacity(0.8),
        content: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Game Over",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "lovelight",
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Your Score: $score",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      startGame();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Play Again",
                      style: TextStyle(
                        fontFamily: "play",
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 760,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 20,
                  ),
                  itemBuilder: (context, index) {
                    if (snakePosition.contains(index)) {
                      return Container(
                        color: Colors.grey.withOpacity(0.6),
                        margin: const EdgeInsets.all(1),
                        child: Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    } else if (index == foodPosition) {
                      return Container(
                        color: Colors.grey.withOpacity(0.6),
                        margin: const EdgeInsets.all(1),
                        child: Image.asset(
                          "images/apple.png",
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return Container(
                        color: Colors.grey.withOpacity(0.6),
                        margin: const EdgeInsets.all(1),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Score: $score ",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
