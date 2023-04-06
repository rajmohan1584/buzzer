import 'package:flutter/material.dart';

class PreServerCheck extends StatefulWidget {
  const PreServerCheck({super.key});

  @override
  State<PreServerCheck> createState() => _PreServerCheckState();
}

class _PreServerCheckState extends State<PreServerCheck> {
  @override
  void initState() {
    // Check for prev interrupted game cache

    // If no game cache - start new game.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Preparing QuizMaster..."));
  }
}
