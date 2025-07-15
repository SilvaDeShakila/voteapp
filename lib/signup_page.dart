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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF46A0FC), Color(0xFF6D5DF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, size: 64, color: Color(0xFF46A0FC)),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF46A0FC),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF46A0FC),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : _signup,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onLoginTap,
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 