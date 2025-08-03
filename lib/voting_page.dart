import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'models/election_model.dart';
import 'biometric_service.dart';

class VotingPage extends StatefulWidget {
  final ElectionModel election;
  const VotingPage({Key? key, required this.election}) : super(key: key);

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  String? _selectedOption;
  bool _isLoading = false;
  bool _isCheckingBiometrics = false;
  String? _error;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _isCheckingBiometrics = true;
    });

    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final biometrics = await BiometricService.getAvailableBiometrics();
      
      setState(() {
        _biometricAvailable = isAvailable;
        _availableBiometrics = biometrics;
        _isCheckingBiometrics = false;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _isCheckingBiometrics = false;
      });
    }
  }

  Future<void> _castVote() async {
    if (_selectedOption == null) {
      setState(() {
        _error = 'Please select an option to vote';
      });
      return;
    }

    // Check biometric availability first
    if (!_biometricAvailable) {
      setState(() {
        _error = 'Biometric authentication is not available on this device';
      });
      return;
    }

    // Perform biometric authentication
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      setState(() {
        _error = 'Biometric authentication failed. Please try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if election is still active
      final electionDoc = await FirebaseFirestore.instance
          .collection('elections')
          .doc(widget.election.id)
          .get();

      if (!electionDoc.exists) {
        throw Exception('Election not found');
      }

      final election = ElectionModel.fromMap({
        'id': electionDoc.id,
        ...electionDoc.data() as Map<String, dynamic>
      });

      if (!election.isActive || DateTime.now().isAfter(election.endDate)) {
        throw Exception('This election has ended');
      }

      // Check if user has already voted
      final voterDoc = await FirebaseFirestore.instance
          .collection('elections')
          .doc(widget.election.id)
          .collection('voters')
          .doc(user.uid)
          .get();

      if (voterDoc.exists) {
        throw Exception('You have already voted in this election');
      }

      // Use a transaction to update votes atomically
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Record the vote in voters subcollection first
        await FirebaseFirestore.instance
            .collection('elections')
            .doc(widget.election.id)
            .collection('voters')
            .doc(user.uid)
            .set({
          'timestamp': FieldValue.serverTimestamp(),
          'option': _selectedOption,
        });

        // Then update the vote count
        final updatedVotes = Map<String, int>.from(election.votes);
        updatedVotes[_selectedOption!] = (updatedVotes[_selectedOption!] ?? 0) + 1;

        await FirebaseFirestore.instance
            .collection('elections')
            .doc(widget.election.id)
            .update({'votes': updatedVotes});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote cast successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cast Your Vote'),
        backgroundColor: Color(0xFF2E3192),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.election.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.election.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Biometric status card
            if (_isCheckingBiometrics)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Checking biometric availability...'),
                    ],
                  ),
                ),
              )
            else if (_biometricAvailable)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fingerprint,
                        color: Colors.green,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biometric Authentication Available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              BiometricService.getBiometricTypeString(_availableBiometrics),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Biometric authentication not available',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 24),
            Text(
              'Select your choice:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
              ),
            ),
            SizedBox(height: 16),
            ...widget.election.options.map((option) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: option,
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value;
                      });
                    },
                    title: Text(option),
                    activeColor: Color(0xFF2E3192),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedOption == option
                            ? Color(0xFF2E3192)
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                )),
            if (_error != null)
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 24),
            
            // Main voting button with biometric authentication
            ElevatedButton(
              onPressed: (_isLoading || !_biometricAvailable || _selectedOption == null) ? null : _castVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E3192),
                padding: EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _availableBiometrics.contains(BiometricType.face) 
                                  ? Icons.face 
                                  : Icons.fingerprint, 
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'VOTE NOW',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Authenticate with ${BiometricService.getBiometricTypeString(_availableBiometrics)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
            ),
            
            SizedBox(height: 16),
            
            // Information card about biometric authentication
            if (_biometricAvailable)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2E3192),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your ${BiometricService.getBiometricTypeString(_availableBiometrics)} will be required to confirm your vote',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}