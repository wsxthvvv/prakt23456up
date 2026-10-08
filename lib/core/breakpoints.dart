import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded, wide }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1100) return ScreenSize.medium;
  if (width < 1600) return ScreenSize.expanded;
  return ScreenSize.wide;
}

bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 1100;

int cardColumnsOf(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 1 : 2;
