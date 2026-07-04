import 'package:flutter/material.dart';
import 'app_initializer.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().initialize();
  runApp(const MedAdhereApp());
}
