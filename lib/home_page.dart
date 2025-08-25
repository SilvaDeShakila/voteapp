import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/election_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'user_model.dart';
import 'profile_page.dart'; // Import the ProfilePage
import 'voting_page.dart'; // Import the VotingPage
import 'splash_screen.dart'; // Import SplashScreen for AuthSwitcher

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'VoteApp',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1a1a1a),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          FutureBuilder<UserModel?>(
            future: AuthService.getUserModel(currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              return Container(
                margin: EdgeInsets.only(right: 16),
                child: PopupMenuButton<String>(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF667eea).withValues(alpha: 0.3),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  offset: Offset(0, 50),
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
                        try {
                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          await FirebaseAuth.instance.signOut();
                          
                          // Close loading dialog
                          Navigator.of(context).pop();
                          
                          // Navigate to splash screen which will redirect to login
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => AuthSwitcher(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        } catch (e) {
                          // Close loading dialog if it's open
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error signing out: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
                ),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildWelcomeCard(),
                SizedBox(height: 40),
                _buildSectionTitle('Active Elections'),
                SizedBox(height: 20),
                if (activeElections.isEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Active Elections',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back later for new voting opportunities',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...activeElections.map((doc) {
                    final election = ElectionModel.fromMap({
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>
                    });
                    return Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: _buildElectionCard(context, election),
                    );
                  }),
                SizedBox(height: 40),
                _buildSectionTitle('Completed Elections'),
                SizedBox(height: 20),
                ...completedElections.map((doc) {
                  final election = ElectionModel.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>
                  });
                  return Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: _buildCompletedElectionCard(election),
                  );
                }),
                SizedBox(height: 20), // Bottom padding
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
            Color(0xFF2E3192),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2E3192).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.how_to_vote_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Welcome to VoteApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Empowering democracy through secure digital voting',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.security,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Secure',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a1a),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, ElectionModel election) {
    final now = DateTime.now();
    final timeLeft = election.endDate.difference(now);
    String timeLeftString;
    Color timeColor;
    IconData timeIcon;
    
    if (timeLeft.inDays > 0) {
      timeLeftString = '${timeLeft.inDays} days left';
      timeColor = Color(0xFF10B981);
      timeIcon = Icons.schedule;
    } else if (timeLeft.inHours > 0) {
      timeLeftString = '${timeLeft.inHours} hours left';
      timeColor = Color(0xFFF59E0B);
      timeIcon = Icons.schedule;
    } else {
      timeLeftString = '${timeLeft.inMinutes} minutes left';
      timeColor = Color(0xFFEF4444);
      timeIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 40,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF667eea).withOpacity(0.1),
                    Color(0xFF764ba2).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.how_to_vote,
                          color: Color(0xFF667eea),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          election.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1a1a1a),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    election.description,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Options section
                  Row(
                    children: [
                      Icon(
                        Icons.ballot_outlined,
                        size: 18,
                        color: Color(0xFF667eea),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Available Options',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...election.options.map((option) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFF667eea),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  SizedBox(height: 24),
                  
                  // Bottom section with time and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Time left
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: timeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: timeColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              timeIcon,
                              size: 16,
                              color: timeColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              timeLeftString,
                              style: TextStyle(
                                color: timeColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Vote button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667eea).withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VotingPage(election: election),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.how_to_vote,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'VOTE NOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    int totalVotes = 0;
    
    election.votes.forEach((option, votes) {
      totalVotes += votes;
      if (votes > maxVotes) {
        maxVotes = votes;
        winningOption = option;
      }
    });

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header with completed status
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF10B981).withOpacity(0.1),
                    Color(0xFF059669).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              election.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1a1a1a),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF10B981).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    election.description,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Results section
            if (winningOption != null)
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Election Results',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Winner card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF59E0B).withOpacity(0.1),
                            Color(0xFFD97706).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFF59E0B).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.emoji_events,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WINNER',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  winningOption!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1a1a1a),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$maxVotes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              Text(
                                'votes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Total votes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Votes Cast',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '$totalVotes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}