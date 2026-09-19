import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void goBack(BuildContext context, {String fallback = '/home'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
