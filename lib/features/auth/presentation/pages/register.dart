import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/validators.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            final failure = state.failure;
            final emailError = failure is ValidationFailure
                ? failure.fieldErrors['email']
                : null;
            if (emailError != null) {
              setState(() => _emailError = emailError);
            } else {
              context.showSnack(failure.message);
            }
          }
        },
        builder: (context, state) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AppTextField(
                label: 'Name',
                controller: _name,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                controller: _email,
                validator: Validators.email,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                controller: _password,
                validator: Validators.password,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Confirm Password',
                controller: _passwordConfirm,
                validator: ((value) =>
                    value != _password.text ? 'Not matching password' : null),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Register new account',
                isLoading: state is AuthLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      RegisterRequested(
                        name: _name.text,
                        email: _email.text,
                        password: _password.text,
                      ),
                    );
                  }
                },
              ),
              AppButton(
                label: 'Already have an account? Log in',
                variant: AppButtonVariant.text,
                onPressed: () => context.go(Routes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
