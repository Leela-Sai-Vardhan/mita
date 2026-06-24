import 'package:flutter/material.dart';

class OnboardingPageData {
  final Widget icon;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final String body;
  final Widget? extraContent;

  const OnboardingPageData({
    required this.icon,
    this.title,
    this.titleWidget,
    this.subtitle,
    required this.body,
    this.extraContent,
  });
}
