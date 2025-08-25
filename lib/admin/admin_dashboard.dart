import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/election_model.dart';
import 'create_election_page.dart';
import 'edit_election_page.dart';
import '../user_model.dart';
import 'election_details_page.dart';

class AdminDashboard extends StatelessWidget {
  final UserModel user;
  const AdminDashboard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF2E3192),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('elections').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final elections = snapshot.data?.docs ?? [];

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildAdminHeader(),
              SizedBox(height: 24),
              _buildStatsCards(elections.length),
              SizedBox(height: 24),
              Text(
                'Active Elections',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3192),
                ),
              ),
              SizedBox(height: 16),
              ...elections.map((doc) {
                final election = ElectionModel.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>
                });
                return _buildElectionCard(context, election);
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateElectionPage(adminUid: user.uid),
            ),
          );
        },
        backgroundColor: Color(0xFF2E3192),
        icon: Icon(Icons.add),
        label: Text('Create Election'),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int totalElections) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Elections',
            totalElections.toString(),
            Icons.how_to_vote,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Elections',
            'Active',
            Icons.timer,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF2E3192), size: 32),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF2E3192),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, ElectionModel election) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              election.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              election.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ends: ${election.endDate.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Color(0xFF2E3192),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ElectionDetailsPage(
                              election: election,
                            ),
                          ),
                        );
                      },
                      child: Text('VIEW DETAILS'),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditElectionPage(election: election),
                            ),
                          );
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, election);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ElectionModel election) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Election'),
          content: Text('Are you sure you want to delete "${election.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteElection(context, election);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteElection(BuildContext context, ElectionModel election) async {
    try {
      // Delete the election document
      await FirebaseFirestore.instance
          .collection('elections')
          .doc(election.id)
          .delete();

      // Delete all voters in the subcollection
      final votersSnapshot = await FirebaseFirestore.instance
          .collection('elections')
          .doc(election.id)
          .collection('voters')
          .get();

      for (var doc in votersSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Election deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting election: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}