import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:github_repo_viewer/auth/application/auth_notifier.dart';
import 'package:github_repo_viewer/auth/shared/providers.dart';
import 'package:github_repo_viewer/core/presentation/routes/app_router.gr.dart';
import 'package:github_repo_viewer/core/shared/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final initializationProvider = FutureProvider<Unit>((ref) async {
  await ref.read(sembastProvider).init();
  ref.read(dioProvider)
    ..options = BaseOptions(
      headers: {
        'Accept': 'application/vnd.github.v3.html+json',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 400,
    )
    ..interceptors.add(ref.read(oAuth2InterceptorProvider));
  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAndUpdateAuthStatus();
  return unit;
});

class AppWidget extends ConsumerWidget {
  final appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(initializationProvider, (_, state) {});
    ref.listen<AuthState>(
      authNotifierProvider,
      (_, state) {
        state.maybeMap(
          orElse: () {
            return null;
          },
          authenticated: (_) {
            appRouter.pushAndPopUntil(
              const StarredReposRoute(),
              predicate: (route) => false,
            );
            return null;
          },
          unauthenticated: (_) {
            appRouter.pushAndPopUntil(
              const SignInRoute(),
              predicate: (route) => false,
            );
            return null;
          },
        );
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Repo Viewer',
      theme: _setUpThemeData(),
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }

  ThemeData _setUpThemeData() {
    return ThemeData(
      primaryColor: Colors.grey.shade50,
    );
  }
}
