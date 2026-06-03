import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.create();
  final ai = AIServiceFactory.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(storage: storage, ai: ai),
      child: const DateWiseApp(),
    ),
  );
}
