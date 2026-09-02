import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class BigMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const BigMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: true,
      label: isListening
          ? 'توقف ضبط صدا'
          : 'شروع ضبط صدا',
      hint: isListening
          ? 'برای توقف و تبدیل صدا به متن دوبار ضربه بزنید'
          : 'برای شروع صحبت کردن دوبار ضربه بزنید',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isListening
                    ? [
                        colorScheme.error,
                        colorScheme.errorContainer,
                      ]
                    : [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? colorScheme.error : colorScheme.primary)
                      .withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 56,
              color: isListening
                  ? colorScheme.onError
                  : colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
