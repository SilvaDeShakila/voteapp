import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/election_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class ElectionDetailsPage extends StatelessWidget {
  final ElectionModel election;
  
  const ElectionDetailsPage({Key? key, required this.election}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Election Details'),
        backgroundColor: Color(0xFF2E3192),
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final isAdmin = adminSnapshot.data?.get('isAdmin') ?? false;
        if (!isAdmin) {
          return Text('Only administrators can view voter details');
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('elections')
              .doc(electionId)
              .collection('voters')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error loading voters: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }

            final voters = snapshot.data!.docs;

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
                    child: Text(
                      'Voters (${voters.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3192),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: voters.length,
                    itemBuilder: (context, index) {
                      final voter = voters[index];
                      final data = voter.data() as Map<String, dynamic>;
                      final timestamp = (data['timestamp'] as Timestamp).toDate();
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(voter.id)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.person, color: Colors.grey[600]),
                              ),
                              title: Text('Loading...'),
                            );
                          }

                          final userEmail = userSnapshot.data?.get('email') ?? 'Unknown';
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF2E3192),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(userEmail),
                            subtitle: Text('Voted: ${_formatDateTime(timestamp)}'),
                            trailing: Text(
                              data['option'],
                              style: TextStyle(
                                color: Color(0xFF2E3192),
                                fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2E3192).withOpacity(0.1),
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
}