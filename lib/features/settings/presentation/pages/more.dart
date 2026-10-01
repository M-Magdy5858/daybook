import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('More Page'),
            if (kDebugMode)
              TextButton.icon(
                onPressed: () => context.go(Routes.gallery),
                icon: const Icon(Icons.widgets_outlined),
                label: const Text('Widget gallery'),
              ),
          ],
        ),
      ),
    );
  }
}
