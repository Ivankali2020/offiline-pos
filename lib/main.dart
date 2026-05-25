import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:abpos/app_bindings.dart';
import 'package:abpos/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await AppBindings.initServices();
  runApp(const AppShell());
  
}
