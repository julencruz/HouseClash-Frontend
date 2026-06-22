import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/onboarding/join_or_create_house_screen.dart';
import '../../features/auth/onboarding/join_house_screen.dart';
import '../../features/auth/onboarding/create_house_screen.dart';
import '../../features/auth/onboarding/house_created_success_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/data/auth_controller.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/cards/presentation/cards_screen.dart';
import '../../features/house/presentation/house_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/auth/domain/task_models.dart';
import '../auth/house_storage.dart';
import '../auth/token_storage.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      final tokenAsync = ref.read(tokenStorageProvider);
      final houseAsync = ref.read(houseStorageProvider);
      final location = state.matchedLocation;

      if (tokenAsync.isLoading || houseAsync.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (location == AppRoutes.splash) {
        final hasToken = tokenAsync.valueOrNull != null;
        final hasHouse = houseAsync.valueOrNull != null;
        if (!hasToken) return AppRoutes.welcome;
        if (!hasHouse) return AppRoutes.joinOrCreateHouse;
        return AppRoutes.tasks;
      }

      final hasToken = tokenAsync.valueOrNull != null;
      final hasHouse = houseAsync.valueOrNull != null;

      final isPublic = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.register;

      final isOnboarding =
          location == AppRoutes.joinOrCreateHouse ||
          location == AppRoutes.joinHouse;

      if (!hasToken) {
        return isPublic ? null : AppRoutes.login;
      }

      if (hasToken && !hasHouse) {
        return (isOnboarding || location == AppRoutes.createHouse) ? null : AppRoutes.joinOrCreateHouse;
      }

      if (hasToken && hasHouse && (isPublic || isOnboarding)) {
        return AppRoutes.tasks;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => const NoTransitionPage(child: _SplashScreen()),
      ),

      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, state) => const NoTransitionPage(child: WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, state) => const NoTransitionPage(child: RegisterScreen()),
      ),

      GoRoute(
        path: AppRoutes.joinOrCreateHouse,
        pageBuilder: (_, state) => const NoTransitionPage(child: JoinOrCreateHouseScreen()),
      ),
      GoRoute(
        path: AppRoutes.joinHouse,
        pageBuilder: (_, __) => const NoTransitionPage(child: JoinHouseScreen()),
      ),
      GoRoute(
        path: AppRoutes.createHouse,
        pageBuilder: (_, __) => const NoTransitionPage(child: CreateHouseScreen()),
      ),
      GoRoute(
        path: AppRoutes.houseCreatedSuccess,
        pageBuilder: (_, state) {
          final inviteCode = state.uri.queryParameters['code'] ?? 'ERROR';
          return NoTransitionPage(child: HouseCreatedSuccessScreen(inviteCode: inviteCode));
        },
      ),

      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, state) => const NoTransitionPage(child: TasksScreen()),
            routes: [
              GoRoute(
                path: ':taskId',
                pageBuilder: (_, state) {
                  final task = state.extra as TaskModel;
                  return MaterialPage(child: TaskDetailScreen(task: task));
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.cards,
            pageBuilder: (_, state) => const NoTransitionPage(child: CardsScreen()),
          ),
          GoRoute(
            path: AppRoutes.ranking,
            pageBuilder: (_, state) => const NoTransitionPage(child: HouseScreen()),
          ),
          GoRoute(
            path: AppRoutes.activity,
            pageBuilder: (_, state) => const NoTransitionPage(child: ActivityScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    AppRoutes.tasks,
    AppRoutes.cards,
    AppRoutes.ranking,
    AppRoutes.activity,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t)).clamp(0, 4);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (i) => context.go(_tabs[i]),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 28,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textHint,

              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_outline_rounded),
                  activeIcon: Icon(Icons.check_circle_rounded),
                  label: 'Tasques',
                ),

                BottomNavigationBarItem(
                  icon: Icon(Symbols.playing_cards, fill: 0.0),
                  activeIcon: Icon(Symbols.playing_cards, fill: 1.0),
                  label: 'Cartes',
                ),

                BottomNavigationBarItem(
                  icon: Icon(Icons.home_work_outlined),
                  activeIcon: Icon(Icons.home_work_rounded),
                  label: 'Casa',
                ),

                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none_rounded),
                  activeIcon: Icon(Icons.notifications_rounded),
                  label: 'Activitat',
                ),

                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(tokenStorageProvider, (_, __) => notifyListeners());
    ref.listen(houseStorageProvider, (_, __) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
