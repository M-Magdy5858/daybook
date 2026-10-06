import 'package:daybook/core/error/failures.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext(); // offer to save the new password
    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _name.text.trim(),
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthFailure) return;
        final failure = state.failure;
        final emailError = failure is ValidationFailure
            ? failure.fieldErrors['email']
            : null;
        if (emailError != null) {
          setState(() => _emailError = emailError);
        } else {
          context.showSnack(failure.message);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return AuthLayout(
          title: 'Create your account',
          subtitle: 'Tasks, calendar, habits and spending in one place.',
          footer: AuthSwitchLink(
            question: 'Already have an account?',
            action: 'Log in',
            onPressed: () => context.go(Routes.login),
          ),
          children: [
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Name',
                      controller: _name,
                      validator: Validators.required,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline,
                      autofillHints: const [AutofillHints.name],
                    ),
                    AppSpacing.gapMd,
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      validator: Validators.email,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
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
                      helperText: 'At least 8 characters',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    AppSpacing.gapMd,
                    AppPasswordField(
                      label: 'Confirm password',
                      controller: _passwordConfirm,
                      validator: (v) =>
                          v == _password.text ? null : "Passwords don't match",
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => loading ? null : _submit(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'Create account',
              expand: true,
              isLoading: loading,
              onPressed: _submit,
            ),
          ],
        );
      },
    );
  }
}
