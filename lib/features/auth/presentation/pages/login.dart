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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) context.showSnack(state.failure.message);
          if (state is Authenticated) context.go(Routes.dashboard);
        },
        builder: (context, state) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                controller: _password,
                validator: Validators.password,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Log in',
                isLoading: state is AuthLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      LoginRequested(
                        email: _email.text,
                        password: _password.text,
                      ),
                    );
                  }
                },
              ),
              AppButton(
                label: 'Create an account',
                variant: AppButtonVariant.text,
                onPressed: () => context.go(Routes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
