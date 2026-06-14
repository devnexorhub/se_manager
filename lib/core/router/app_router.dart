import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/categories/screens/category_list_screen.dart';
import '../../features/categories/screens/add_edit_category_screen.dart';
import '../../features/categories/screens/category_detail_screen.dart';
import '../../features/students/screens/add_edit_student_screen.dart';
import '../../features/students/screens/student_detail_screen.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Application router using GoRouter.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── Splash ───────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Shell (Bottom Navigation) ────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CategoryListScreen(),
          ),
          routes: [
            // ── Add Category ───────────────────────────────────
            GoRoute(
              path: 'add',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const AddEditCategoryScreen(),
            ),

            // ── Category Detail (Members List) ─────────────────
            GoRoute(
              path: ':catId',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final catId = int.parse(state.pathParameters['catId']!);
                return CategoryDetailScreen(categoryId: catId);
              },
              routes: [
                // ── Edit Category ──────────────────────────────
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final catId =
                        int.parse(state.pathParameters['catId']!);
                    return AddEditCategoryScreen(categoryId: catId);
                  },
                ),

                // ── Add Member ─────────────────────────────────
                GoRoute(
                  path: 'members/add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final catId =
                        int.parse(state.pathParameters['catId']!);
                    return AddEditStudentScreen(categoryId: catId);
                  },
                ),

                // ── Member Detail ──────────────────────────────
                GoRoute(
                  path: 'members/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final catId =
                        int.parse(state.pathParameters['catId']!);
                    final id = int.parse(state.pathParameters['id']!);
                    return StudentDetailScreen(
                      studentId: id,
                      categoryId: catId,
                    );
                  },
                  routes: [
                    // ── Edit Member ────────────────────────────
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final catId =
                            int.parse(state.pathParameters['catId']!);
                        final id =
                            int.parse(state.pathParameters['id']!);
                        return AddEditStudentScreen(
                          studentId: id,
                          categoryId: catId,
                        );
                      },
                    ),

                    // ── Add Transaction ────────────────────────
                    GoRoute(
                      path: 'transaction/add',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final catId =
                            int.parse(state.pathParameters['catId']!);
                        final id =
                            int.parse(state.pathParameters['id']!);
                        return AddTransactionScreen(
                          studentId: id,
                          categoryId: catId,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
