import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: Icon(Icons.person_outline_rounded),
            onPressed: () {
              // TODO: Implement profile action
            },
          ),
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
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 24),
            _buildSectionTitle('Active Polls'),
            SizedBox(height: 16),
            _buildPollCard(
              'Student Council Election',
              'Cast your vote for the next student council president',
              '2 days left',
              0.6,
            ),
            SizedBox(height: 16),
            _buildPollCard(
              'Cafeteria Menu Vote',
              'Help us decide next week\'s special menu items',
              '5 hours left',
              0.8,
            ),
            SizedBox(height: 24),
            _buildSectionTitle('Recent Results'),
            SizedBox(height: 16),
            _buildResultCard(
              'Library Hours Extension',
              'Proposal to extend library hours during exam week',
              'Passed with 75% votes',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement create poll action
        },
        backgroundColor: Color(0xFF2E3192),
        icon: Icon(Icons.add),
        label: Text('Create Poll'),
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

  Widget _buildPollCard(String title, String description, String timeLeft, double progress) {
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
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1BFFFF)),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeLeft,
                  style: TextStyle(
                    color: Color(0xFF2E3192),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Implement vote action
                  },
                  child: Text('VOTE NOW'),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF2E3192),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String description, String result) {
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              result,
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