import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isPasswordless = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthService>();
    bool success;
    
    if (_isPasswordless) {
      success = await auth.sendSignInLink(_emailController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for the sign-in link!')),
        );
      }
    } else if (_isLogin) {
      success = await auth.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await auth.registerWithEmail(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
    }
    
    if (!success && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    
    final auth = context.read<AuthService>();
    final success = await auth.sendPasswordResetEmail(_emailController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Password reset email sent!' 
              : auth.error ?? 'Error sending email'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceLight, width: 3),
                  ),
                  child: const Icon(
                    Icons.circle,
                    size: 60,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Master Checkers',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back!' : 'Create your account',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isLogin && !_isPasswordless)
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      if (!_isLogin) const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      
                      if (!_isPasswordless) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit Button
                Consumer<AuthService>(
                  builder: (context, auth, _) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isPasswordless 
                              ? 'Send Sign-In Link' 
                              : (_isLogin ? 'Log In' : 'Sign Up')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthService>().signInWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.surfaceLight),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Toggle Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _isPasswordless = false;
                      }),
                      child: Text(_isLogin 
                          ? "Don't have an account? Sign Up" 
                          : 'Already have an account? Log In'),
                    ),
                  ],
                ),
                
                if (_isLogin) ...[
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot Password?'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isPasswordless = !_isPasswordless),
                    child: Text(_isPasswordless 
                        ? 'Use Password Instead' 
                        : 'Sign In with Email Link'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
