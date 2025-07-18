import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/election_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'user_model.dart';
import 'profile_page.dart'; // Import the ProfilePage
import 'voting_page.dart'; // Import the VotingPage

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF2E3192),
        title: Text(
          'VoteApp',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FutureBuilder<UserModel?>(
            future: AuthService.getUserModel(currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF2E3192),
                  ),
                ),
                offset: Offset(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text(snapshot.data?.email ?? 'Loading...'),
                      subtitle: Text('User Profile'),
                    ),
                    value: 'profile',
                  ),
                  PopupMenuItem<String>(
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Voting History'),
                    ),
                    value: 'history',
                  ),
                  PopupMenuItem<String>(
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                    ),
                    value: 'settings',
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    value: 'logout',
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'logout':
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                      break;
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(),
                        ),
                      );
                      break;
                    case 'history':
                      // TODO: Navigate to voting history
                      break;
                    case 'settings':
                      // TODO: Navigate to settings
                      break;
                  }
                },
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3192).withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('elections')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final elections = snapshot.data?.docs ?? [];
            final activeElections = elections.where((doc) {
              final election = ElectionModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              });
              return DateTime.now().isBefore(election.endDate);
            }).toList();

            final completedElections = elections.where((doc) {
              final election = ElectionModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              });
              return DateTime.now().isAfter(election.endDate);
            }).toList();

            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildWelcomeCard(),
                SizedBox(height: 24),
                _buildSectionTitle('Active Elections'),
                SizedBox(height: 16),
                if (activeElections.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No active elections at the moment',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ...activeElections.map((doc) {
                    final election = ElectionModel.fromMap({
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>
                    });
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildElectionCard(context, election),
                    );
                  }),
                SizedBox(height: 24),
                _buildSectionTitle('Completed Elections'),
                SizedBox(height: 16),
                ...completedElections.map((doc) {
                  final election = ElectionModel.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>
                  });
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _buildCompletedElectionCard(election),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.how_to_vote_rounded,
              size: 48,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to VoteApp!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your voice matters. Make it count!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E3192),
        ),
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, ElectionModel election) {
    final now = DateTime.now();
    final timeLeft = election.endDate.difference(now);
    String timeLeftString;
    if (timeLeft.inDays > 0) {
      timeLeftString = '${timeLeft.inDays} days left';
    } else if (timeLeft.inHours > 0) {
      timeLeftString = '${timeLeft.inHours} hours left';
    } else {
      timeLeftString = '${timeLeft.inMinutes} minutes left';
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              election.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              election.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Options:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
              ),
            ),
            ...election.options.map((option) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $option'),
                )),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeLeftString,
                  style: TextStyle(
                    color: Color(0xFF2E3192),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VotingPage(election: election),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E3192),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('VOTE NOW'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedElectionCard(ElectionModel election) {
    // Calculate the winning option
    String? winningOption;
    int maxVotes = 0;
    election.votes.forEach((option, votes) {
      if (votes > maxVotes) {
        maxVotes = votes;
        winningOption = option;
      }
    });

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    election.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              election.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            if (winningOption != null)
              Text(
                'Winner: $winningOption',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}