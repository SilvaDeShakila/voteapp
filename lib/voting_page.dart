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
        // Get the current election document
        final electionRef = FirebaseFirestore.instance
            .collection('elections')
            .doc(widget.election.id);
        
        final electionSnapshot = await transaction.get(electionRef);
        
        if (!electionSnapshot.exists) {
          throw Exception('Election not found');
        }
        
        final currentData = electionSnapshot.data()!;
        final currentVotes = Map<String, int>.from(currentData['votes'] ?? {});
        
        // Update the vote count
        currentVotes[_selectedOption!] = (currentVotes[_selectedOption!] ?? 0) + 1;
        
        // Record the vote in voters subcollection
        final voterRef = FirebaseFirestore.instance
            .collection('elections')
            .doc(widget.election.id)
            .collection('voters')
            .doc(user.uid);
            
        transaction.set(voterRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'option': _selectedOption,
        });
        
        // Update the election vote counts
        transaction.update(electionRef, {'votes': currentVotes});
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
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: (_isLoading || !_biometricAvailable || _selectedOption == null)
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Color(0xFF667eea), 
                          Color(0xFF764ba2),
                          Color(0xFFf093fb),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isLoading || !_biometricAvailable || _selectedOption == null)
                        ? Colors.grey.withValues(alpha: 0.3)
                        : Color(0xFF667eea).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_isLoading || !_biometricAvailable || _selectedOption == null) ? null : _castVote,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _isLoading
                        ? Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Casting Vote...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _availableBiometrics.contains(BiometricType.face) 
                                      ? Icons.face_rounded 
                                      : Icons.fingerprint, 
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 20),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CAST YOUR VOTE',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                          color: Colors.black.withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Secure • Verified • Anonymous',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
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