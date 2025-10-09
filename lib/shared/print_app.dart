import 'dart:async';
import 'dart:developer';

void appPrint({
  String message = 'Log',
  String name = 'debug',
  Object? error,
  int level = 0,
  int? sequenceNumber,
  StackTrace? stackTrace,
  DateTime? time,
  Zone? zone,
}) =>
    log(
      message,
      name: name,
      error: error,
      level: level,
      sequenceNumber: sequenceNumber,
      stackTrace: stackTrace,
      time: time,
      zone: zone,
    );
