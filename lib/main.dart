import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'src/app.dart';
import 'src/authentication/authentication.dart';
import 'src/home_widget/home_widget.dart';
import 'src/logs/logs.dart';
import 'src/settings/cubit/settings_cubit.dart';
import 'src/storage/storage_service.dart';
import 'src/window/app_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appWindow = await AppWindow.initialize();

  if (Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  initializeLogger();

  final storageService = await StorageService.initialize();

  final googleAuth = GoogleAuth();
  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: googleAuth,
    storageService: storageService,
  );

  final _settingsCubit = await SettingsCubit.initialize(storageService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: googleAuth),
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => authenticationCubit),
          BlocProvider.value(value: _settingsCubit),
        ],
        child: const App(),
      ),
    ),
  );
}

/// Used for Background Updates using Workmanager Plugin
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        'Updated from Background',
      ),
      HomeWidget.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
      HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  });
}

/// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri? data) async {
  print('clicky?');
  print(data);

  if (data?.host == 'titleclicked') {
    final greetings = [
      'frog',
      'fox',
      'wolf',
      'amaterasu',
    ];
    final selectedGreeting = greetings[Random().nextInt(greetings.length)];

    await updateHomeWidget('title', selectedGreeting);
  }
}
