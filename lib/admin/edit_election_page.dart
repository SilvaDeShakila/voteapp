import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/election_model.dart';

class EditElectionPage extends StatefulWidget {
  final ElectionModel election;
  const EditElectionPage({Key? key, required this.election}) : super(key: key);

  @override
  State<EditElectionPage> createState() => _EditElectionPageState();
}

class _EditElectionPageState extends State<EditElectionPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<TextEditingController> _optionControllers;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _error;
  bool _hasVotes = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.election.title);
    _descriptionController = TextEditingController(text: widget.election.description);
    _startDate = widget.election.startDate;
    _endDate = widget.election.endDate;
    
    // Initialize option controllers
    _optionControllers = widget.election.options
        .map((option) => TextEditingController(text: option))
        .toList();
    
    // Check if election has votes
    _hasVotes = widget.election.votes.values.any((count) => count > 0);
  }

  Future<void> _updateElection() async {
    // Validate inputs
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    // Validate options
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      setState(() {
        _error = 'Please add at least 2 options';
      });
      return;
    }

    // Check if election has started and has votes
    if (_hasVotes && DateTime.now().isAfter(_startDate!)) {
      // Only allow title and description changes after votes are cast
      final originalOptions = Set.from(widget.election.options);
      final newOptions = Set.from(options);
      
      if (!originalOptions.containsAll(newOptions) || originalOptions.length != newOptions.length) {
        setState(() {
          _error = 'Cannot modify options after voting has started';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Prepare updated data
      Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
      };

      // Only update options if no votes have been cast
      if (!_hasVotes || DateTime.now().isBefore(_startDate!)) {
        updateData['options'] = options;
        // Reset votes if options changed
        Map<String, int> newVotes = {};
        for (String option in options) {
          newVotes[option] = widget.election.votes[option] ?? 0;
        }
        updateData['votes'] = newVotes;
      }

      await FirebaseFirestore.instance
          .collection('elections')
          .doc(widget.election.id)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Election updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Failed to update election: $e';
        _isLoading = false;
      });
    }
  }

  void _addOption() {
    if (_hasVotes && DateTime.now().isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add options after voting has started'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_hasVotes && DateTime.now().isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove options after voting has started'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Must have at least 2 options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEditOptions = !_hasVotes || DateTime.now().isBefore(_startDate!);
    final electionEnded = DateTime.now().isAfter(_endDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Election'),
        backgroundColor: Color(0xFF2E3192),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasVotes)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canEditOptions 
                            ? 'This election has votes. Options cannot be modified after voting starts.'
                            : 'Voting has started. Only title and description can be modified.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (electionEnded)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This election has ended. Changes may not affect voting.',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Election Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: Text('Start Date'),
                      subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Not set'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: canEditOptions ? () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      } : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: Text('End Date'),
                      subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Not set'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...List.generate(
              _optionControllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        enabled: canEditOptions,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (canEditOptions && _optionControllers.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            if (canEditOptions)
              TextButton.icon(
                onPressed: _addOption,
                icon: Icon(Icons.add),
                label: Text('Add Option'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateElection,
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
                      'Update Election',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
