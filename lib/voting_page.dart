import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/election_model.dart';

class VotingPage extends StatefulWidget {
  final ElectionModel election;
  const VotingPage({Key? key, required this.election}) : super(key: key);

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  String? _selectedOption;
  bool _isLoading = false;
  String? _error;

  Future<void> _castVote() async {
    if (_selectedOption == null) {
      setState(() {
        _error = 'Please select an option to vote';
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
            ElevatedButton(
              onPressed: _isLoading ? null : _castVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E3192),
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Cast Vote',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}