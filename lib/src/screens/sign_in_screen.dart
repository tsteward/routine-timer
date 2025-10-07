import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_state_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _showEmailAuth = false;
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmailAuth() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      context.read<AuthBloc>().add(
        SignUpWithEmailPassword(email: email, password: password),
      );
    } else {
      context.read<AuthBloc>().add(
        SignInWithEmailPassword(email: email, password: password),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: state.errorMessage!.contains('sent')
                    ? Colors.green
                    : Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // App Logo/Title
                    const Icon(Icons.timer, size: 100, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      'Routine Timer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your morning routine with ease',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 64),

                    if (!_showEmailAuth) ...[
                      // OAuth Buttons
                      // Google Sign-In Button
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const SignInWithGoogle(),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email/Password Button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showEmailAuth = true;
                            _isSignUp = false;
                          });
                        },
                        icon: const Icon(Icons.email),
                        label: const Text('Sign in with Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Guest Sign-In Button
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const SignInAnonymously(),
                          );
                        },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continue as Guest'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info Text
                      const Text(
                        'Guest accounts can be upgraded to full accounts later',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ] else ...[
                      // Email/Password Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white54,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.white70,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white54,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.white70,
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (_isSignUp && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _submitEmailAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Forgot Password (only for sign in)
                            if (!_isSignUp)
                              TextButton(
                                onPressed: () {
                                  final email = _emailController.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter your email first',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<AuthBloc>().add(
                                    SendPasswordReset(email),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Toggle Sign In / Sign Up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already have an account? '
                                      : 'Don\'t have an account? ',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                    });
                                  },
                                  child: Text(
                                    _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Back Button
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showEmailAuth = false;
                                  _emailController.clear();
                                  _passwordController.clear();
                                });
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Other Sign-In Options'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
