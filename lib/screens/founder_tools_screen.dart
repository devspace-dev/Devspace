import 'package:flutter/material.dart';

import '../services/backend_api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/founder_access_denied_view.dart';

class FounderToolsScreen extends StatefulWidget {
  const FounderToolsScreen({super.key});

  @override
  State<FounderToolsScreen> createState() => _FounderToolsScreenState();
}

class _FounderToolsScreenState extends State<FounderToolsScreen> {
  final _eventFormKey = GlobalKey<FormState>();
  final _challengeFormKey = GlobalKey<FormState>();

  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventRequiredAuraController = TextEditingController(text: '0');
  final _eventLinkController = TextEditingController();

  final _challengeTitleController = TextEditingController();
  final _challengeDescriptionController = TextEditingController();
  final _challengeTechStackController = TextEditingController();
  final _challengePointsController = TextEditingController(text: '20');

  String _eventType = 'event';
  String _challengeDifficulty = 'easy';
  bool _isCreatingEvent = false;
  bool _isCreatingChallenge = false;
  bool _isLoadingAdminData = true;
  bool _isCheckingFounderAccess = true;
  bool _hasFounderAccess = false;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
    _initializeFounderAccess();
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventRequiredAuraController.dispose();
    _eventLinkController.dispose();
    _challengeTitleController.dispose();
    _challengeDescriptionController.dispose();
    _challengeTechStackController.dispose();
    _challengePointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingFounderAccess) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(
          backgroundColor: AppColors.bgFor(context),
          title: Text(
            'Founder Tools',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (!_hasFounderAccess) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(
          backgroundColor: AppColors.bgFor(context),
          title: Text(
            'Founder Tools',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
        ),
        body: const FounderAccessDeniedView(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(
          backgroundColor: AppColors.bgFor(context),
          title: Text(
            'Founder Tools',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Challenges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventsTab(context),
            _buildChallengesTab(context),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeFounderAccess() async {
    final hasAccess = await BackendApiService.instance.hasFounderAccess();
    if (!mounted) return;

    setState(() {
      _hasFounderAccess = hasAccess;
      _isCheckingFounderAccess = false;
    });

    if (hasAccess) {
      await _loadAdminData();
    }
  }

  Widget _buildEventsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const _IntroCard(
          title: 'Create opportunity access',
          description:
              'Seed hackathons and events here. Eligibility is enforced by aura on the backend.',
        ),
        const SizedBox(height: 16),
        Form(
          key: _eventFormKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Title',
                child: TextFormField(
                  controller: _eventTitleController,
                  decoration: const InputDecoration(
                    hintText: 'Campus hackathon',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _eventDescriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'What this opportunity is about',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Required aura',
                child: TextFormField(
                  controller: _eventRequiredAuraController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                  ),
                  validator: _nonNegativeNumberValidator,
                ),
              ),
              _LabeledField(
                label: 'Link',
                child: TextFormField(
                  controller: _eventLinkController,
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Type',
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'event', label: Text('Event')),
                    ButtonSegment(value: 'hackathon', label: Text('Hackathon')),
                  ],
                  selected: {_eventType},
                  onSelectionChanged: (selection) {
                    setState(() => _eventType = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreatingEvent ? null : _createEvent,
                  child: Text(
                    _isCreatingEvent ? 'Creating...' : 'Create Event',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _AdminSectionHeader(
          title: 'Manage events',
          onRefresh: _loadAdminData,
        ),
        const SizedBox(height: 12),
        if (_isLoadingAdminData)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (_events.isEmpty)
          const _EmptyAdminState(message: 'No events created yet.')
        else
          ..._events.map(
            (event) => _AdminItemCard(
              title: event['title']?.toString() ?? 'Untitled event',
              subtitle:
                  '${event['type']} • aura ${event['required_aura'] ?? 0} • ${_activeLabel(event['is_active'])}',
              description: event['description']?.toString() ?? '',
              onEdit: () => _editEvent(event),
              onDeactivate: (event['is_active'] as bool? ?? true)
                  ? () => _deactivateEvent(event['id'].toString())
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildChallengesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const _IntroCard(
          title: 'Seed daily challenges',
          description:
              'Add challenge templates for React, DSA, Backend, or general tracks. Assignment stays backend-driven.',
        ),
        const SizedBox(height: 16),
        Form(
          key: _challengeFormKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Title',
                child: TextFormField(
                  controller: _challengeTitleController,
                  decoration: const InputDecoration(
                    hintText: 'Build a paginated feed endpoint',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _challengeDescriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Explain the task clearly for students',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Tech stack',
                child: TextFormField(
                  controller: _challengeTechStackController,
                  decoration: const InputDecoration(
                    hintText: 'React, DSA, Backend, General',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Points reward',
                child: TextFormField(
                  controller: _challengePointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '20',
                  ),
                  validator: _positiveNumberValidator,
                ),
              ),
              _LabeledField(
                label: 'Difficulty',
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'easy', label: Text('Easy')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'hard', label: Text('Hard')),
                  ],
                  selected: {_challengeDifficulty},
                  onSelectionChanged: (selection) {
                    setState(() => _challengeDifficulty = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreatingChallenge ? null : _createChallenge,
                  child: Text(
                    _isCreatingChallenge ? 'Creating...' : 'Create Challenge',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _AdminSectionHeader(
          title: 'Manage challenges',
          onRefresh: _loadAdminData,
        ),
        const SizedBox(height: 12),
        if (_isLoadingAdminData)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (_challenges.isEmpty)
          const _EmptyAdminState(message: 'No challenges created yet.')
        else
          ..._challenges.map(
            (challenge) => _AdminItemCard(
              title: challenge['title']?.toString() ?? 'Untitled challenge',
              subtitle:
                  '${challenge['difficulty']} • ${challenge['tech_stack']} • +${challenge['points_reward']} • ${_activeLabel(challenge['is_active'])}',
              description: challenge['description']?.toString() ?? '',
              onEdit: () => _editChallenge(challenge),
              onDeactivate: (challenge['is_active'] as bool? ?? true)
                  ? () => _deactivateChallenge(challenge['id'].toString())
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    setState(() => _isLoadingAdminData = true);

    try {
      final results = await Future.wait<dynamic>([
        BackendApiService.instance.getAdminEvents(),
        BackendApiService.instance.getAdminChallenges(),
      ]);

      if (!mounted) return;
      setState(() {
        _events = results[0] as List<Map<String, dynamic>>;
        _challenges = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      _showSnack('Failed to load founder data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAdminData = false);
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_eventFormKey.currentState!.validate()) return;

    setState(() => _isCreatingEvent = true);
    try {
      await BackendApiService.instance.createEvent(
        title: _eventTitleController.text.trim(),
        description: _eventDescriptionController.text.trim(),
        requiredAura: int.parse(_eventRequiredAuraController.text.trim()),
        link: _eventLinkController.text.trim(),
        type: _eventType,
      );

      _eventTitleController.clear();
      _eventDescriptionController.clear();
      _eventRequiredAuraController.text = '0';
      _eventLinkController.clear();
      await _loadAdminData();
      _showSnack('Event created.');
    } catch (e) {
      _showSnack('Failed to create event: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreatingEvent = false);
      }
    }
  }

  Future<void> _createChallenge() async {
    if (!_challengeFormKey.currentState!.validate()) return;

    setState(() => _isCreatingChallenge = true);
    try {
      await BackendApiService.instance.createChallenge(
        title: _challengeTitleController.text.trim(),
        description: _challengeDescriptionController.text.trim(),
        difficulty: _challengeDifficulty,
        techStack: _challengeTechStackController.text.trim(),
        pointsReward: int.parse(_challengePointsController.text.trim()),
      );

      _challengeTitleController.clear();
      _challengeDescriptionController.clear();
      _challengeTechStackController.clear();
      _challengePointsController.text = '20';
      await _loadAdminData();
      _showSnack('Challenge created.');
    } catch (e) {
      _showSnack('Failed to create challenge: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreatingChallenge = false);
      }
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final titleController = TextEditingController(
      text: event['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: event['description']?.toString() ?? '',
    );
    final auraController = TextEditingController(
      text: '${event['required_aura'] ?? 0}',
    );
    final linkController = TextEditingController(
      text: event['link']?.toString() ?? '',
    );
    var eventType = event['type']?.toString() ?? 'event';
    var isActive = event['is_active'] as bool? ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: auraController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Required aura',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(labelText: 'Link'),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'event', label: Text('Event')),
                        ButtonSegment(
                          value: 'hackathon',
                          label: Text('Hackathon'),
                        ),
                      ],
                      selected: {eventType},
                      onSelectionChanged: (selection) {
                        setDialogState(() => eventType = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await BackendApiService.instance.updateEvent(
          eventId: event['id'].toString(),
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          requiredAura: int.tryParse(auraController.text.trim()) ?? 0,
          link: linkController.text.trim(),
          type: eventType,
          isActive: isActive,
        );
        await _loadAdminData();
        _showSnack('Event updated.');
      } catch (e) {
        _showSnack('Failed to update event: $e');
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    auraController.dispose();
    linkController.dispose();
  }

  Future<void> _editChallenge(Map<String, dynamic> challenge) async {
    final titleController = TextEditingController(
      text: challenge['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: challenge['description']?.toString() ?? '',
    );
    final stackController = TextEditingController(
      text: challenge['tech_stack']?.toString() ?? '',
    );
    final pointsController = TextEditingController(
      text: '${challenge['points_reward'] ?? 20}',
    );
    var difficulty = challenge['difficulty']?.toString() ?? 'easy';
    var isActive = challenge['is_active'] as bool? ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit challenge'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stackController,
                      decoration:
                          const InputDecoration(labelText: 'Tech stack'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points reward',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'easy', label: Text('Easy')),
                        ButtonSegment(value: 'medium', label: Text('Medium')),
                        ButtonSegment(value: 'hard', label: Text('Hard')),
                      ],
                      selected: {difficulty},
                      onSelectionChanged: (selection) {
                        setDialogState(() => difficulty = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await BackendApiService.instance.updateChallenge(
          challengeId: challenge['id'].toString(),
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          difficulty: difficulty,
          techStack: stackController.text.trim(),
          pointsReward: int.tryParse(pointsController.text.trim()) ?? 20,
          isActive: isActive,
        );
        await _loadAdminData();
        _showSnack('Challenge updated.');
      } catch (e) {
        _showSnack('Failed to update challenge: $e');
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    stackController.dispose();
    pointsController.dispose();
  }

  Future<void> _deactivateEvent(String eventId) async {
    try {
      await BackendApiService.instance.deactivateEvent(eventId);
      await _loadAdminData();
      _showSnack('Event deactivated.');
    } catch (e) {
      _showSnack('Failed to deactivate event: $e');
    }
  }

  Future<void> _deactivateChallenge(String challengeId) async {
    try {
      await BackendApiService.instance.deactivateChallenge(challengeId);
      await _loadAdminData();
      _showSnack('Challenge deactivated.');
    } catch (e) {
      _showSnack('Failed to deactivate challenge: $e');
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _nonNegativeNumberValidator(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Enter 0 or more';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a positive number';
    }
    return null;
  }

  String _activeLabel(dynamic value) => value == true ? 'active' : 'inactive';

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String title;
  final String description;

  const _IntroCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.text2For(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  final String title;
  final Future<void> Function() onRefresh;

  const _AdminSectionHeader({
    required this.title,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
            ),
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _AdminItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  const _AdminItemCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              if (onDeactivate != null)
                TextButton(
                  onPressed: onDeactivate,
                  child: const Text('Deactivate'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  final String message;

  const _EmptyAdminState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.text3For(context),
        ),
      ),
    );
  }
}
