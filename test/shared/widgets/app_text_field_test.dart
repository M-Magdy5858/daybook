import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('shows label, hint, error text and prefix icon', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Email',
          hint: 'you@example.com',
          errorText: 'Required',
          prefixIcon: Icons.email,
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('reports typed text through onChanged and controller', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? changed;
      await tester.pumpApp(
        AppTextField(
          label: 'Name',
          controller: controller,
          onChanged: (value) => changed = value,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Daybook');

      expect(changed, 'Daybook');
      expect(controller.text, 'Daybook');
    });

    testWidgets('runs validator inside a Form', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpApp(
        Form(
          key: formKey,
          child: AppTextField(
            label: 'Name',
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Name is required' : null,
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpApp(
        const AppTextField(label: 'Password', obscureText: true),
      );

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
    });
  });
}
