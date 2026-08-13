import 'package:flutter/material.dart';

class CaughtButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const CaughtButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Center(
        child: SizedBox(
          width: 220,
          height: 55,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            child: const Text("I'VE BEEN CAUGHT"),
          ),
        ),
      ),
    );
  }
}
