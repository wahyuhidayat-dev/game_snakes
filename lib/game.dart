// ignore_for_file: library_private_types_in_public_api, unnecessary_null_comparison, prefer_conditional_assignment

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'controll_pannel.dart';
import 'direction.dart';
import 'piece.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  List<Offset> positions = [];
  int length = 5;
  int step = 20;
  Direction direction = Direction.right;

  late Piece food;
  Offset foodPosition = const Offset(100.0, 100.0);

  late double screenWidth;
  late double screenHeight;
  late int lowerBoundX, upperBoundX, lowerBoundY, upperBoundY;

  late Timer timer;
  double speed = 0.15;

  int score = 0;
  int _start = 10;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    timer = Timer.periodic(
      oneSec,
      (Timer timers) {
        if (_start == 0) {
          setState(() {
            timers.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void draw() async {
    if (positions.isEmpty) {
      positions.add(getRandomPositionWithinRange());
    }

    while (length > positions.length) {
      positions.add(positions[positions.length - 1]);
    }

    for (int i = positions.length - 1; i > 0; i--) {
      positions[i] = positions[i - 1];
    }

    positions[0] = await getNextPosition(positions[0]);
  }

  Direction getRandomDirection([String? type]) {
    if (type == "horizontal") {
      bool random = Random().nextBool();
      if (random) {
        return Direction.right;
      } else {
        return Direction.left;
      }
    } else if (type == "vertical") {
      bool random = Random().nextBool();
      if (random) {
        return Direction.up;
      } else {
        return Direction.down;
      }
    } else {
      int random = Random().nextInt(4);
      return Direction.values[random];
    }
  }

  Offset getRandomPositionWithinRange() {
    int posX = Random().nextInt(upperBoundX) + lowerBoundX;
    int posY = Random().nextInt(upperBoundY) + lowerBoundY;
    return Offset(roundToNearestTens(posX).toDouble(),
        roundToNearestTens(posY).toDouble());
  }

  bool detectCollision(Offset position) {
    if (position.dx >= upperBoundX && direction == Direction.right) {
      return true;
    } else if (position.dx <= lowerBoundX && direction == Direction.left) {
      return true;
    } else if (position.dy >= upperBoundY && direction == Direction.down) {
      return true;
    } else if (position.dy <= lowerBoundY && direction == Direction.up) {
      return true;
    }

    return false;
  }

  void showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.red,
          shape: const RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.black,
                width: 3.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: const Text(
            "Game Over",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Your game is over but you played well.\nYour score is $score.",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  restart();
                  Navigator.of(context).pop();
                });
              },
              child: const Text(
                "Restart",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Offset> getNextPosition(Offset position) async {
    Offset nextPosition = Offset(position.dx, position.dy);

    if (detectCollision(position) == true) {
      if (timer != null && timer.isActive) timer.cancel();
      await Future.delayed(
          const Duration(milliseconds: 500), () => showGameOverDialog());
      return position;
    }

    if (direction == Direction.right) {
      nextPosition = Offset(position.dx + step, position.dy);
    } else if (direction == Direction.left) {
      nextPosition = Offset(position.dx - step, position.dy);
    } else if (direction == Direction.up) {
      nextPosition = Offset(position.dx, position.dy - step);
    } else if (direction == Direction.down) {
      nextPosition = Offset(position.dx, position.dy + step);
    }

    return nextPosition;
  }

  void drawFood() {
    if (foodPosition == null) {
      foodPosition = getRandomPositionWithinRange();
    }

    if (foodPosition == positions[0]) {
      length++;
      speed = speed + 0.25;
      score = score + 5;
      changeSpeed();

      foodPosition = getRandomPositionWithinRange();
    }

    food = Piece(
      posX: foodPosition.dx.toInt(),
      posY: foodPosition.dy.toInt(),
      size: step,
      color: Colors.redAccent,
      isAnimated: true,
    );
  }

  List<Piece> getPieces() {
    List<Piece> pieces = [];
    draw();
    drawFood();

    for (var i = 0; i < positions.length; ++i) {
      Piece p = Piece(
        posX: positions[i].dx.toInt(),
        posY: positions[i].dy.toInt(),
        size: step,
        color: Colors.red,
      );

      pieces.add(p);
      print(pieces.toString());
    }

    return pieces;
  }

  Widget getControls() {
    return ControlPanel(
      onTapped: (Direction newDirection) {
        direction = newDirection;
      },
    );
  }

  int roundToNearestTens(int num) {
    int divisor = step;
    int output = (num ~/ divisor) * divisor;
    if (output == 0) {
      output += step;
    }
    return output;
  }

// ! Change Speed
  void changeSpeed() {
    if (timer != null && timer.isActive) timer.cancel();

    timer = Timer.periodic(Duration(milliseconds: 500 ~/ speed), (timer) {
      setState(() {});
    });
  }

  Widget getScore() {
    return Positioned(
      top: 50.0,
      right: 40.0,
      child: Text(
        "Score: $score",
        style: const TextStyle(fontSize: 24.0),
      ),
    );
  }

  void restart() {
    setState(() {
      // foodPosition = Offset(100, 100);
      // food = Piece(posX: 100, posY: 100, size: step);
      length = 5;
      positions = [];
      direction = getRandomDirection();
      speed = 1;
      score = 0;
      changeSpeed();
      // Navigator.of(context).pop();
      // animationController.dispose();
    });
  }

  Widget getPlayAreaBorder() {
    return Positioned(
      top: lowerBoundY.toDouble(),
      left: lowerBoundX.toDouble(),
      child: Container(
        width: (upperBoundX - lowerBoundX + step).toDouble(),
        height: (upperBoundY - lowerBoundY + step).toDouble(),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            style: BorderStyle.solid,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  late AnimationController animationController;
  @override
  void initState() {
    super.initState();
    startTimer();
    restart();
    animationController = AnimationController(
      lowerBound: 0.25,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    lowerBoundX = step;
    lowerBoundY = step;
    upperBoundX = roundToNearestTens(screenWidth.toInt() - step);
    upperBoundY = roundToNearestTens(screenHeight.toInt() - step);

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0XFFFFD1DA),
          child: Stack(
            children: [
              getPlayAreaBorder(),
              ...getPieces(),
              getControls(),
              food,
              getScore(),
            ],
          ),
        ),
      ),
    );
  }
}
