import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(methodCount: 0, printTime: true),
);
