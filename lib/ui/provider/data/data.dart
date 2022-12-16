
import 'package:flutter/material.dart';

class Data with ChangeNotifier {
  static final Data _instance = Data._internal();

  factory Data() {
    return _instance;
  }

  Data._internal();
  String? token;
}