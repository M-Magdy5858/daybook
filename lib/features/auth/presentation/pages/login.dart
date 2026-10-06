import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/validators.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/auth/presentation/widgets/auth_layout.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_password_field.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext(); // offer to save the password
    context.read<AuthBloc>().add(
      LoginRequested(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) context.showSnack(state.failure.message);
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return AuthLayout(
          title: 'Welcome back',
          subtitle: 'Log in to pick up where you left off.',
          footer: AuthSwitchLink(
            question: 'New to Daybook?',
            action: 'Create an account',
            onPressed: () => context.go(Routes.register),
          ),
          children: [
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.mail_outline,
                      autofillHints: const [AutofillHints.email],
                    ),
                    AppSpacing.gapMd,
                    AppPasswordField(
                      label: 'Password',
                      controller: _password,
                      validator: Validators.password,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => loading ? null : _submit(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'Log in',
              expand: true,
              isLoading: loading,
              onPressed: _submit,
            ),
            if (kDebugMode) ...[
              AppSpacing.gapSm,
              _DemoAccountHint(
                onUse: () {
                  _email.text = 'demo@daybook.dev';
                  _password.text = 'password123';
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Debug builds only: fills in the mock server's demo account.
class _DemoAccountHint extends StatelessWidget {
  const _DemoAccountHint({required this.onUse});

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onUse,
      icon: const Icon(Icons.bolt_outlined, size: 18),
      label: const Text('Use demo account'),
    );
  }
}
