import 'package:flutter/material.dart';

/// A soft fade between notebook pages.
Route<T> fadeRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 350)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
  );
}
