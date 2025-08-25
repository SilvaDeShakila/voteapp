import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/election_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'edit_election_page.dart';

class ElectionDetailsPage extends StatelessWidget {
  final ElectionModel election;
  
  const ElectionDetailsPage({Key? key, required this.election}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Election Details'),
        backgroundColor: Color(0xFF2E3192),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditElectionPage(election: election),
                  ),
                );
                if (result == true) {
                  // Refresh handled by StreamBuilder
                }
              } else if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Election'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Election', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('elections')
            .doc(election.id)
            .snapshots(),
        builder: (context, electionSnapshot) {
          if (electionSnapshot.hasError) {
            return Center(child: Text('Error: ${electionSnapshot.error}'));
          }

          if (!electionSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final updatedElection = ElectionModel.fromMap({
            'id': electionSnapshot.data!.id,
            ...electionSnapshot.data!.data() as Map<String, dynamic>
          });

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildElectionOverview(updatedElection),
                SizedBox(height: 24),
                _buildVotingStats(updatedElection),
                SizedBox(height: 24),
                _buildVotersList(election.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildElectionOverview(ElectionModel election) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              election.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
              ),
            ),
            SizedBox(height: 8),
            Text(
              election.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('Start: ${_formatDate(election.startDate)}'),
                SizedBox(width: 8),
                _buildInfoChip('End: ${_formatDate(election.endDate)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStats(ElectionModel election) {
    final totalVotes = election.votes.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voting Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: election.votes.values.fold(0, max) + 2,
                  barGroups: election.votes.entries.map((entry) {
                    return BarChartGroupData(
                      x: election.options.indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Color(0xFF2E3192),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              election.options[value.toInt()],
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Total Votes: $totalVotes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotersList(String electionId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('elections')
          .doc(electionId)
          .collection('voters')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text('Error loading voters: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading voters...'),
                ],
              ),
            ),
          );
        }

        final voters = snapshot.data?.docs ?? [];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Color(0xFF2E3192)),
                    SizedBox(width: 8),
                    Text(
                      'Voters (${voters.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3192),
                      ),
                    ),
                  ],
                ),
              ),
              if (voters.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.how_to_vote, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('No votes cast yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: voters.length,
                  itemBuilder: (context, index) {
                    final voter = voters[index];
                    final data = voter.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null 
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final option = data['option'] ?? 'Unknown';
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(voter.id)
                          .get(),
                      builder: (context, userSnapshot) {
                        String userEmail = 'Loading...';
                        String userDisplay = 'Voter';
                        
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          userEmail = 'Loading...';
                        } else if (userSnapshot.hasError) {
                          userEmail = 'Error loading user';
                          userDisplay = 'Anonymous Voter';
                        } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          userEmail = userData?['email'] ?? 'Unknown User';
                          userDisplay = userEmail;
                        } else {
                          userEmail = 'User not found';
                          userDisplay = 'Anonymous Voter';
                        }
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF2E3192),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            userDisplay,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voted: ${_formatDateTime(timestamp)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (userSnapshot.hasError)
                                Text(
                                  'User ID: ${voter.id}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF2E3192).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                color: Color(0xFF2E3192),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2E3192).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color(0xFF2E3192),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(BuildContext context) {
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
                await _deleteElection(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteElection(BuildContext context) async {
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

      Navigator.of(context).pop(); // Go back to admin dashboard
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