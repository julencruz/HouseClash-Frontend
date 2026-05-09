import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/house_storage.dart';
import '../auth/token_storage.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final tokenAsync = ref.watch(tokenStorageProvider);
  final houseAsync = ref.watch(houseStorageProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      if (tokenAsync.isLoading || houseAsync.isLoading) return null;

      final hasToken = tokenAsync.valueOrNull != null;
      final hasHouse = houseAsync.valueOrNull != null;
      final location = state.matchedLocation;

      final isPublic = location == AppRoutes.login ||
          location == AppRoutes.register;

      final isOnboarding = location == AppRoutes.joinHouse ||
          location == AppRoutes.createHouse;

      if (!hasToken) {
        return isPublic ? null : AppRoutes.login;
      }

      if (hasToken && !hasHouse) {
        return isOnboarding ? null : AppRoutes.joinHouse;
      }

      if (hasToken && hasHouse && (isPublic || isOnboarding)) {
        return AppRoutes.tasks;
      }
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const PlaceholderScreen(label: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const PlaceholderScreen(label: 'Register'),
      ),

      // Onboarding casa
      GoRoute(
        path: AppRoutes.joinHouse,
        builder: (_, __) => const PlaceholderScreen(label: 'Unir-se a una casa'),
      ),
      GoRoute(
        path: AppRoutes.createHouse,
        builder: (_, __) => const PlaceholderScreen(label: 'Crear casa'),
      ),

      // Shell amb bottom nav
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, state) => const NoTransitionPage(child: PlaceholderScreen(label: 'Tasques')),
            routes: [
              GoRoute(
                path: ':taskId',
                builder: (_, state) => PlaceholderScreen(
                  label: 'Detall tasca ${state.pathParameters['taskId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.cards,
            pageBuilder: (_, state) => const NoTransitionPage(child: PlaceholderScreen(label: 'Cartes')),
            routes: [
              GoRoute(
                path: ':cardId',
                builder: (_, state) => PlaceholderScreen(
                  label: 'Detall carta ${state.pathParameters['cardId']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ranking,
            pageBuilder: (_, state) => const NoTransitionPage(child: PlaceholderScreen(label: 'Rànquing')),
          ),
          GoRoute(
            path: AppRoutes.activity,
            pageBuilder: (_, state) => const NoTransitionPage(child: PlaceholderScreen(label: 'Activitat')),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, state) => const NoTransitionPage(child: PlaceholderScreen(label: 'Perfil')),
          ),
        ],
      ),
    ],
  );
}

// Main menu amb bottom nav
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
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events_rounded),
                  label: 'Rànquing',
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

// ── Placeholder reutilitzable ────────────────────────────
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
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