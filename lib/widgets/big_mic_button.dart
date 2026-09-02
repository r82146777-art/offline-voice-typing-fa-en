import 'package:flutter/material.dart';

class BigMicButton extends StatelessWidget {
  final bool isListening;
  final bool enabled;
  final VoidCallback onPressed;

  const BigMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      label: isListening ? 'توقف ضبط صدا' : 'شروع ضبط صدا',
      hint: isListening
          ? 'برای توقف و درج متن دوبار ضربه بزنید'
          : 'برای شروع صحبت کردن دوبار ضربه بزنید',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: !enabled
                    ? [Colors.grey.shade500, Colors.grey.shade700]
                    : isListening
                        ? [colorScheme.error, colorScheme.errorContainer]
                        : [colorScheme.primary, colorScheme.primaryContainer],
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: (isListening ? colorScheme.error : colorScheme.primary)
                            .withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 54,
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
