import 'package:flutter/material.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../utils/validators.dart';
import '../../../asset_library/presentation/pages/dashboard_page.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  final bool sessionExpired;

  const LoginPage({super.key, this.sessionExpired = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _signUpMode = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) _error = 'Your session expired — please sign in again.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _signUpMode = !_signUpMode;
      _error = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _submit() async {
    final emailError = Validators.email(_emailController.text);
    final passwordError = _signUpMode
        ? Validators.password(_passwordController.text)
        : Validators.required(_passwordController.text, label: 'Password');
    final validationError = emailError ?? passwordError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    await _run(
          () => _signUpMode
          ? _authService.signUp(email: _emailController.text, password: _passwordController.text)
          : _authService.signIn(email: _emailController.text, password: _passwordController.text),
      fallback: _signUpMode ? 'Could not create your account.' : 'Could not sign in. Check your credentials.',
    );
  }

  Future<void> _handleDemo() => _run(
    _authService.continueAsDemo,
    fallback: 'Could not start the demo session.',
  );

  Future<void> _run(Future<UserModel> Function() action, {required String fallback}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      _goToDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e, fallback: fallback);
        _loading = false;
      });
    }
  }

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.7),
            radius: 1.0,
            colors: [AppColors.accentSoft, AppColors.paper],
            stops: [0.0, 0.65],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.titleLarge,
                            children: const [
                              TextSpan(text: 'Brand'),
                              TextSpan(text: 'Vault', style: TextStyle(color: AppColors.accent)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "One place for the brand's colors, logo, and assets.",
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _passwordController,
                          label: _signUpMode ? 'Password (8+ characters, letter + number)' : 'Password',
                          obscureText: true,
                          onSubmitted: (_) => _loading ? null : _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_signUpMode ? 'Create account' : 'Sign in'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _handleDemo,
                            child: const Text('Continue as demo'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _toggleMode,
                            child: Text(_signUpMode ? 'Already have an account? Sign in' : 'New here? Create an account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AppApiClient.useMock) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Mock mode — running on sample data, no backend connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}