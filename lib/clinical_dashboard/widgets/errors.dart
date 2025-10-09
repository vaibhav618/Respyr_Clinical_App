import 'package:flutter/material.dart';

class Errors{

  Scaffold showDashboardLoadError({required String errorMessage}){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(errorMessage),
      ),
    );
  }
}
