import 'package:flutter/material.dart';

IconData subjectIcon(String subject) {
  switch (subject) {
    case '国語':
      return Icons.menu_book;
    case '算数':
      return Icons.calculate;
    case '理科':
      return Icons.science;
    case '社会':
      return Icons.public;
    case '英語':
      return Icons.language;
    default:
      return Icons.description;
  }
}
