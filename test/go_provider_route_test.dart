import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_provider/go_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:nested/nested.dart';

void main() {
  testWidgets(
    'keeps parent GoProviderRoute providers when navigating nested routes',
    (tester) async {
      var creates = 0;
      var disposes = 0;

      final router = GoRouter(
        initialLocation: '/history',
        routes: [
          GoProviderRoute(
            path: '/history',
            providers: (context, state) => [
              _TrackingProvider(
                onCreate: () => creates++,
                onDispose: () => disposes++,
              ),
            ],
            builder: (context, state) => const Text('history'),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) =>
                    Text('detail ${state.pathParameters['id']}'),
              ),
            ],
          ),
          GoRoute(
            path: '/other',
            builder: (context, state) => const Text('other'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('history'), findsOneWidget);
      expect(creates, 1);
      expect(disposes, 0);

      router.go('/history/detail/1');
      await tester.pumpAndSettle();

      expect(find.text('detail 1'), findsOneWidget);
      expect(creates, 1);
      expect(disposes, 0);

      router.go('/history');
      await tester.pumpAndSettle();

      expect(find.text('history'), findsOneWidget);
      expect(creates, 1);
      expect(disposes, 0);

      router.go('/other');
      await tester.pumpAndSettle();

      expect(find.text('other'), findsOneWidget);
      expect(disposes, 1);
    },
  );
}

class _TrackingProvider extends SingleChildStatefulWidget {
  const _TrackingProvider({required this.onCreate, required this.onDispose});

  final VoidCallback onCreate;
  final VoidCallback onDispose;

  @override
  State<_TrackingProvider> createState() => _TrackingProviderState();
}

class _TrackingProviderState extends SingleChildState<_TrackingProvider> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return child ?? const SizedBox.shrink();
  }
}
