import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback? onLoginTap;
  const SignupPage({Key? key, this.onLoginTap}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      print('Attempting to sign up with email: $email'); // Debug print
      
      // Validate password length
      if (password.length < 6) {
        setState(() {
          _loading = false;
          _error = 'Password must be at least 6 characters long';
        });
        return;
      }
      
      // Try signup with multiple attempts if needed
      Map<String, dynamic> result;
      int attempts = 0;
      do {
        result = await AuthService.signUp(email, password);
        if (result['user'] != null) break;
        attempts++;
        if (attempts < 3) await Future.delayed(Duration(milliseconds: 500 * attempts));
      } while (attempts < 3 && result['error']?.toString().contains('PigeonUserDetails') == true);
      
      if (result['error'] != null) {
        print('Sign up failed - Detailed error: ${result['error']}'); // More detailed debug print
        setState(() {
          _loading = false;
          _error = result['error'] as String;
        });
        return;
      }
      
      if (result['user'] == null) {
        print('Sign up failed - User is null but no error provided'); // Debug edge case
        setState(() {
          _loading = false;
          _error = 'Registration failed. Please try again.';
        });
        return;
      }

      final user = result['user'] as User;

      print('User created successfully, creating UserModel...'); // Debug print
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );

      print('Saving user model to Firestore...'); // Debug print
      try {
        // Create the user document in Firestore
        await AuthService.saveUserModel(userModel);
        print('User model saved successfully'); // Debug print
        
        // Clear loading state and navigate to login
        setState(() {
          _loading = false;
          _error = null;
        });
        
        if (widget.onLoginTap != null) {
          widget.onLoginTap!();
        }
      } catch (firestoreError) {
        print('Error saving user model: $firestoreError'); // Debug print
        
        // If it's a permission error, we should handle it differently
        if (firestoreError.toString().contains('permission-denied')) {
          // Delete the Firebase Auth user since we couldn't save their data
          try {
            await FirebaseAuth.instance.currentUser?.delete();
          } catch (e) {
            print('Error deleting incomplete user: $e');
          }
          
          setState(() {
            _loading = false;
            _error = 'Unable to complete signup. Please try again later.';
          });
        } else {
          setState(() {
            _loading = false;
            _error = 'Account created but failed to save additional data. Please try again.';
          });
        }
      }
    } catch (e) {
      print('Signup error: $e'); // Debug print
      setState(() {
        _loading = false;
        String errorMessage = 'An unknown error occurred';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already registered';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak (at least 6 characters)';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address';
        }
        _error = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1BFFFF),
              Color(0xFF2E3192),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 16,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1BFFFF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.how_to_reg_rounded,
                          size: 72,
                          color: Color(0xFF2E3192),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join us to make your voice heard',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFF2E3192)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Create a password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFF2E3192)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E3192),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _loading ? null : _signup,
                          child: _loading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: widget.onLoginTap,
                        child: Text(
                          "Already have an account? Login",
                          style: TextStyle(
                            color: Color(0xFF2E3192),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}