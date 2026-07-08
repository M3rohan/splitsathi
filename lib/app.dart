import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_router.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/core/theme/theme_cubit.dart';

class SplitSathiApp extends StatefulWidget {
  const SplitSathiApp({super.key});

  @override
  State<SplitSathiApp> createState() => _SplitSathiAppState();
}

class _SplitSathiAppState extends State<SplitSathiApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'SplitSathi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

class _TempHomeScreen extends StatelessWidget {
  const _TempHomeScreen();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SplitSathi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Setup Working', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<ThemeCubit>().toggleTheme();
              },
              child: Text('Toggle Theme'),
            ),
          ],
        ),
      ),
    );
  }
}
