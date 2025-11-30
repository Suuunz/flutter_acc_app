import 'package:flutter/material.dart';
import '../constants/theme.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool isLoading;
  final VoidCallback onTap;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isRecording ? 80 : 70,
        height: isRecording ? 80 : 70,
        decoration: BoxDecoration(
          color: isRecording ? Colors.redAccent : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : AppColors.primary).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 5,
            )
          ],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }
}