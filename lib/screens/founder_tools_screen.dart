import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/backend_api_service.dart';
import '../services/founder_device_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/founder_access_denied_view.dart';

enum FounderToolsMode { founderTools, developerDashboard }

class FounderToolsScreen extends StatefulWidget {
  final FounderToolsMode mode;

  const FounderToolsScreen({
    super.key,
    this.mode = FounderToolsMode.founderTools,
  });

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
  final _eventBannerUrlController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventOrganizerController = TextEditingController();

  final _challengeTitleController = TextEditingController();
  final _challengeDescriptionController = TextEditingController();
  final _challengeTechStackController = TextEditingController();
  final _challengePointsController = TextEditingController(text: '20');
  final _challengePublishDateController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );
  final _challengeOptionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String _eventType = 'event';
  String? _challengeCorrectAnswer;
  bool _isCreatingEvent = false;
  bool _isCreatingChallenge = false;
  bool _isLoadingEvents = true;
  bool _isLoadingChallenges = true;
  bool _isCheckingFounderAccess = true;
  bool _hasFounderAccess = false;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _challenges = [];
  String? _eventsError;
  String? _challengesError;

  bool get _isDeveloperDashboard =>
      widget.mode == FounderToolsMode.developerDashboard;
  String get _screenTitle =>
      _isDeveloperDashboard ? 'Developer Dashboard' : 'Founder Tools';

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
    _eventBannerUrlController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _eventOrganizerController.dispose();
    _challengeTitleController.dispose();
    _challengeDescriptionController.dispose();
    _challengeTechStackController.dispose();
    _challengePointsController.dispose();
    _challengePublishDateController.dispose();
    for (final controller in _challengeOptionControllers) {
      controller.dispose();
    }
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
            _screenTitle,
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
            _screenTitle,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
        ),
        body: const FounderAccessDeniedView(),
      );
    }

    final me = context.read<AuthProvider>().currentUserOrNull;
    final isFounder = me?.isFounder ?? false;
    final showSystemTab = isFounder && !_isDeveloperDashboard;
    final tabCount = _isDeveloperDashboard ? 1 : (showSystemTab ? 3 : 2);

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(
          backgroundColor: AppColors.bgFor(context),
          title: Text(
            _screenTitle,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
          bottom: TabBar(
            tabs: [
              if (_isDeveloperDashboard) const Tab(text: 'System'),
              if (!_isDeveloperDashboard) const Tab(text: 'Events'),
              if (!_isDeveloperDashboard) const Tab(text: 'Missions'),
              if (showSystemTab) const Tab(text: 'System'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (_isDeveloperDashboard) _buildSystemTab(context),
            if (!_isDeveloperDashboard) _buildEventsTab(context),
            if (!_isDeveloperDashboard) _buildChallengesTab(context),
            if (showSystemTab) _buildSystemTab(context),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeFounderAccess() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final isFounder = me?.isFounder ?? false;

    if (isFounder) {
      if (!mounted) return;
      setState(() {
        _hasFounderAccess = true;
        _isCheckingFounderAccess = false;
      });
      if (!_isDeveloperDashboard) {
        await _loadAdminData();
      }
      return;
    }

    final hasAccess = await BackendApiService.instance.hasFounderAccess();
    if (!mounted) return;

    setState(() {
      _hasFounderAccess = hasAccess;
      _isCheckingFounderAccess = false;
    });

    if (hasAccess && !_isDeveloperDashboard) {
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
                label: 'Banner Image URL',
                child: TextFormField(
                  controller: _eventBannerUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://images.unsplash.com/...',
                  ),
                ),
              ),
              _LabeledField(
                label: 'Event Date (e.g., Apr 20, 10 AM)',
                child: TextFormField(
                  controller: _eventDateController,
                  decoration: const InputDecoration(
                    hintText: 'April 20th, 2026',
                  ),
                ),
              ),
              _LabeledField(
                label: 'Location',
                child: TextFormField(
                  controller: _eventLocationController,
                  decoration: const InputDecoration(
                    hintText: 'Auditorium / Online',
                  ),
                ),
              ),
              _LabeledField(
                label: 'Organizer / Club Name',
                child: TextFormField(
                  controller: _eventOrganizerController,
                  decoration: const InputDecoration(
                    hintText: 'GDG DevSpace',
                  ),
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
          onRefresh: _loadEvents,
        ),
        const SizedBox(height: 12),
        if (_isLoadingEvents)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (_eventsError != null)
          _EmptyAdminState(message: _eventsError!)
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
          title: 'Seed daily missions',
          description:
              'Create the daily MCQ students will answer. Add answer options and mark the right one so the app can validate submissions instantly.',
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
                    hintText: 'Debug a Flutter login flow',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Question',
                child: TextFormField(
                  controller: _challengeDescriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write the question students should answer',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Tech stack',
                child: TextFormField(
                  controller: _challengeTechStackController,
                  decoration: const InputDecoration(
                    hintText: 'Flutter, React, Backend, General',
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
                label: 'Publish Date (YYYY-MM-DD)',
                child: TextFormField(
                  controller: _challengePublishDateController,
                  decoration: const InputDecoration(
                    hintText: '2026-03-28',
                  ),
                  validator: _requiredValidator,
                ),
              ),
              _LabeledField(
                label: 'Options',
                child: Column(
                  children: List.generate(
                    _challengeOptionControllers.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index == _challengeOptionControllers.length - 1
                                ? 0
                                : 12,
                      ),
                      child: TextFormField(
                        controller: _challengeOptionControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Option ${index + 1}',
                        ),
                        validator: index < 2 ? _requiredValidator : null,
                        onChanged: (_) {
                          final selected = _challengeCorrectAnswer;
                          final options = _trimmedMissionOptions(
                            _challengeOptionControllers,
                          );
                          if (selected != null && !options.contains(selected)) {
                            setState(() => _challengeCorrectAnswer = null);
                          } else {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              _LabeledField(
                label: 'Right answer',
                child: DropdownButtonFormField<String>(
                  value: _challengeCorrectAnswer,
                  decoration: const InputDecoration(
                    hintText: 'Choose the correct option',
                  ),
                  items: _buildCorrectAnswerItems(_challengeOptionControllers),
                  onChanged: (value) {
                    setState(() => _challengeCorrectAnswer = value);
                  },
                  validator: (_) => _correctAnswerValidator(
                    _challengeCorrectAnswer,
                    _challengeOptionControllers,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreatingChallenge ? null : _createChallenge,
                  child: Text(
                    _isCreatingChallenge ? 'Creating...' : 'Create Mission',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _AdminSectionHeader(
          title: 'Manage missions',
          onRefresh: _loadChallenges,
          actions: [
            TextButton.icon(
              onPressed: _bulkImportChallenges,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Bulk Import'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingChallenges)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (_challengesError != null)
          _EmptyAdminState(message: _challengesError!)
        else if (_challenges.isEmpty)
          const _EmptyAdminState(message: 'No missions created yet.')
        else
          ..._challenges.map(
            (challenge) => _AdminItemCard(
              title: challenge['title']?.toString() ?? 'Untitled mission',
              subtitle:
                  '${challenge['type']} • ${challenge['tech_stack']} • +${challenge['points_reward']} • ${_activeLabel(challenge['is_active'])}',
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

  Widget _buildSystemTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _IntroCard(
          title: 'Developer dashboard',
          description:
              'System-only tools for monitoring platform status, backend readiness, and internal operations.',
        ),
        const SizedBox(height: 20),
        _SystemActionTile(
          icon: Icons.analytics_outlined,
          title: 'Backend status',
          subtitle: 'Check whether admin APIs and edge functions are available.',
          onTap: _checkBackendStatus,
        ),
        _SystemActionTile(
          icon: Icons.security_outlined,
          title: 'Founder device access',
          subtitle: 'Verify whether this device is allowlisted for admin actions.',
          onTap: _checkFounderDeviceAccess,
        ),
        _SystemActionTile(
          icon: Icons.phone_android_outlined,
          title: 'Copy device ID',
          subtitle: 'Copy this phone device ID so you can allowlist it in Supabase.',
          onTap: _copyFounderDeviceId,
        ),
        _SystemActionTile(
          icon: Icons.event_note_outlined,
          title: 'Events pipeline',
          subtitle: 'Confirm event management routes are working.',
          onTap: _checkEventsRoute,
        ),
        _SystemActionTile(
          icon: Icons.task_alt_outlined,
          title: 'Mission pipeline',
          subtitle: 'Confirm mission management routes are working.',
          onTap: _checkChallengesRoute,
        ),
      ],
    );
  }

  Future<void> _loadAdminData() async {
    await Future.wait([
      _loadEvents(),
      _loadChallenges(),
    ]);
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final events = await BackendApiService.instance.getAdminEvents();
      if (!mounted) return;
      setState(() => _events = events);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _events = [];
        _eventsError = _featureErrorMessage(
          feature: 'events',
          error: e,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;
    setState(() {
      _isLoadingChallenges = true;
      _challengesError = null;
    });

    try {
      final challenges = (await BackendApiService.instance.getAdminMissions())
          .map(_mapMissionToScreenItem)
          .toList();
      if (!mounted) return;
      setState(() => _challenges = challenges);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _challenges = [];
        _challengesError = _featureErrorMessage(
          feature: 'missions',
          error: e,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingChallenges = false);
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
        bannerUrl: _eventBannerUrlController.text.trim(),
        date: _eventDateController.text.trim(),
        location: _eventLocationController.text.trim(),
        organizer: _eventOrganizerController.text.trim(),
      );

      _eventTitleController.clear();
      _eventDescriptionController.clear();
      _eventRequiredAuraController.text = '0';
      _eventLinkController.clear();
      _eventBannerUrlController.clear();
      _eventDateController.clear();
      _eventLocationController.clear();
      _eventOrganizerController.clear();
      await _loadEvents();
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

    final options = _trimmedMissionOptions(_challengeOptionControllers);
    final correctAnswer = _challengeCorrectAnswer?.trim();
    if (correctAnswer == null || correctAnswer.isEmpty) {
      _showSnack('Pick the correct answer before creating the mission.');
      return;
    }

    setState(() => _isCreatingChallenge = true);
    try {
      await BackendApiService.instance.createMission(
        title: _challengeTitleController.text.trim(),
        type: 'mcq',
        techStack: _challengeTechStackController.text.trim(),
        question: _challengeDescriptionController.text.trim(),
        options: options,
        publishDate: _challengePublishDateController.text.trim(),
        pointsReward: int.parse(_challengePointsController.text.trim()),
        correctAnswer: correctAnswer,
      );

      final title = _challengeTitleController.text.trim();
      final techStack = _challengeTechStackController.text.trim();
      
      _challengeTitleController.clear();
      _challengeDescriptionController.clear();
      _challengeTechStackController.clear();
      _challengePointsController.text = '20';
      _challengePublishDateController.text =
          DateTime.now().toIso8601String().split('T')[0];
      for (final controller in _challengeOptionControllers) {
        controller.clear();
      }
      _challengeCorrectAnswer = null;
      await _loadChallenges();
      _showSnack('Mission created.');

      // Notify users about the new mission
      try {
        await NotificationService.instance.notifyNewMission(
          title: title,
          techStack: techStack,
        );
      } catch (e) {
        debugPrint('Failed to send mission notification: $e');
      }
    } catch (e) {
      _showSnack(
        'Failed to create mission: ${BackendApiService.instance.cleanErrorText(e)}',
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingChallenge = false);
      }
    }
  }

  Future<void> _bulkImportChallenges() async {
    final jsonController = TextEditingController(
      text: '''
[
  {
    "title": "Flutter: State Management",
    "techStack": "Flutter",
    "question": "Explain the difference between Provider and Riverpod in Flutter.",
    "options": ["State Management Libraries", "UI Rendering Engines", "Networking Libraries", "Testing Frameworks"],
    "correctAnswer": "State Management Libraries",
    "pointsReward": 50,
    "publishDate": "${DateTime.now().toIso8601String().split('T')[0]}"
  },
  {
    "title": "Node.js: Async Patterns",
    "techStack": "Node.js",
    "question": "What is the purpose of Promises in JavaScript?",
    "options": ["Error Handling", "Asynchronous Operations", "Data Validation", "API Authentication"],
    "correctAnswer": "Asynchronous Operations",
    "pointsReward": 40,
    "publishDate": "${DateTime.now().toIso8601String().split('T')[0]}"
  }
]
''',
    );

    final imported = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bulk Import Missions'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste a JSON array of missions below. Ensure each object has title, techStack, question, options (list), correctAnswer, pointsReward, and publishDate.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jsonController,
                  maxLines: 12,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: '[{"title": "...", "techStack": "...", ...}]',
                    border: OutlineInputBorder(),
                  ),
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
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (imported == true) {
      try {
        final jsonString = jsonController.text.trim();
        if (jsonString.isEmpty) {
          _showSnack('Please paste valid JSON data.');
          return;
        }
        
        final data = jsonDecode(jsonString);
        if (data is! List) throw 'Input must be a JSON array';

        final List<Map<String, dynamic>> missions =
            data.map((m) => Map<String, dynamic>.from(m as Map)).toList();

        if (missions.isEmpty) throw 'No missions found in JSON data';

        await BackendApiService.instance.bulkCreateMissions(missions);
        await _loadChallenges();
        _showSnack('Successfully imported ${missions.length} missions.');
      } catch (e) {
        _showSnack('Import failed: ${BackendApiService.instance.cleanErrorText(e)}');
        debugPrint('Bulk import error: $e');
      }
    }
    jsonController.dispose();
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
    final bannerUrlController = TextEditingController(
      text: event['banner_url']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: event['date']?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: event['location']?.toString() ?? '',
    );
    final organizerController = TextEditingController(
      text: event['organizer']?.toString() ?? '',
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
                    TextField(
                      controller: bannerUrlController,
                      decoration: const InputDecoration(labelText: 'Banner URL'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: organizerController,
                      decoration: const InputDecoration(labelText: 'Organizer'),
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
          bannerUrl: bannerUrlController.text.trim(),
          date: dateController.text.trim(),
          location: locationController.text.trim(),
          organizer: organizerController.text.trim(),
        );
        await _loadEvents();
        _showSnack('Event updated.');
      } catch (e) {
        _showSnack('Failed to update event: $e');
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    auraController.dispose();
    linkController.dispose();
    bannerUrlController.dispose();
    dateController.dispose();
    locationController.dispose();
    organizerController.dispose();
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
    final options = (challenge['options'] as List? ?? const [])
        .map((option) => option.toString())
        .toList();
    final optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: index < options.length ? options[index] : '',
      ),
    );
    var correctAnswer = challenge['correct_answer']?.toString();
    var isActive = challenge['is_active'] as bool? ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit mission'),
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
                    ...List.generate(
                      optionControllers.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index == optionControllers.length - 1 ? 0 : 12,
                        ),
                        child: TextField(
                          controller: optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                          ),
                          onChanged: (_) {
                            final trimmedOptions = _trimmedMissionOptions(
                              optionControllers,
                            );
                            if (correctAnswer != null &&
                                !trimmedOptions.contains(correctAnswer)) {
                              setDialogState(() => correctAnswer = null);
                            } else {
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: correctAnswer,
                      decoration: const InputDecoration(
                        labelText: 'Right answer',
                      ),
                      items: _buildCorrectAnswerItems(optionControllers),
                      onChanged: (value) {
                        setDialogState(() => correctAnswer = value);
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
      final trimmedOptions = _trimmedMissionOptions(optionControllers);
      if (trimmedOptions.length < 2) {
        _showSnack('Add at least two answer options.');
      } else if (correctAnswer == null ||
          !trimmedOptions.contains(correctAnswer)) {
        _showSnack('Choose one valid option as the right answer.');
      } else {
        try {
          final pDate = challenge['publish_date']?.toString();
          final resolvedPublishDate = pDate != null && pDate.isNotEmpty ? pDate : DateTime.now().toIso8601String().split('T')[0];

          await BackendApiService.instance.updateMission(
            missionId: challenge['id'].toString(),
            title: titleController.text.trim(),
            type: 'mcq',
            techStack: stackController.text.trim(),
            question: descriptionController.text.trim(),
            options: trimmedOptions,
            pointsReward: int.tryParse(pointsController.text.trim()) ?? 20,
            publishDate: resolvedPublishDate,
            isActive: isActive,
            correctAnswer: correctAnswer!,
          );
          await _loadChallenges();
          _showSnack('Mission updated.');
        } catch (e) {
          _showSnack(
            'Failed to update mission: ${BackendApiService.instance.cleanErrorText(e)}',
          );
        }
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    stackController.dispose();
    pointsController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }

  Future<void> _deactivateEvent(String eventId) async {
    try {
      await BackendApiService.instance.deactivateEvent(eventId);
      await _loadEvents();
      _showSnack('Event deactivated.');
    } catch (e) {
      _showSnack(
        'Failed to deactivate event: ${BackendApiService.instance.cleanErrorText(e)}',
      );
      debugPrint('Error deactivating event $eventId: $e');
    }
  }

  Future<void> _deactivateChallenge(String challengeId) async {
    try {
      await BackendApiService.instance.deactivateMission(challengeId);
      await _loadChallenges();
      _showSnack('Mission deactivated.');
    } catch (e) {
      _showSnack(
        'Failed to deactivate mission: ${BackendApiService.instance.cleanErrorText(e)}',
      );
    }
  }

  Map<String, dynamic> _mapMissionToScreenItem(Map<String, dynamic> mission) {
    final type = mission['type']?.toString() ?? 'mcq';

    return {
      'id': mission['id'],
      'title': mission['title'],
      'description': mission['question'] ?? '',
      'tech_stack': mission['tech_stack'] ?? '',
      'points_reward': mission['points_reward'] ?? 0,
      'is_active': mission['is_active'] ?? true,
      'type': type,
      'options': (mission['options'] as List? ?? const [])
          .map((option) => option.toString())
          .toList(),
      'correct_answer': mission['correct_answer'],
      'publish_date': mission['publish_date'],
    };
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

  List<String> _trimmedMissionOptions(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();
  }

  List<DropdownMenuItem<String>> _buildCorrectAnswerItems(
    List<TextEditingController> controllers,
  ) {
    final options = _trimmedMissionOptions(controllers).toSet().toList();
    return options
        .map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  String? _correctAnswerValidator(
    String? selectedAnswer,
    List<TextEditingController> controllers,
  ) {
    final options = _trimmedMissionOptions(controllers);
    if (options.length < 2) {
      return 'Add at least two options';
    }
    if (selectedAnswer == null || !options.contains(selectedAnswer)) {
      return 'Select the right answer';
    }
    return null;
  }

  String _activeLabel(dynamic value) => value == true ? 'active' : 'inactive';

  String _featureErrorMessage({
    required String feature,
    required Object error,
  }) {
    final message = BackendApiService.instance.cleanErrorText(error);
    if (message.toLowerCase().contains('backend route not found')) {
      return 'The $feature admin route is not deployed yet. Deploy the latest edge functions for $feature.';
    }

    return 'Failed to load $feature data: $message';
  }

  Future<void> _checkBackendStatus() async {
    try {
      await BackendApiService.instance.getAdminEvents();
      if (!mounted) return;
      _showSnack('Backend status: admin event routes are responding.');
    } catch (eventError) {
      try {
        await BackendApiService.instance.getAdminMissions();
        if (!mounted) return;
        _showSnack('Backend partially ready: missions work, events need attention.');
      } catch (_) {
        if (!mounted) return;
        _showSnack('Backend routes are not fully deployed yet.');
      }
    }
  }

  Future<void> _checkFounderDeviceAccess() async {
    try {
      final hasAccess = await BackendApiService.instance.hasFounderAccess();
      if (!mounted) return;
      _showSnack(
        hasAccess
            ? 'This device is allowlisted for founder actions.'
            : 'This device is not allowlisted for founder actions.',
      );
    } catch (e) {
      _showSnack('Failed to verify founder device access: $e');
    }
  }

  Future<void> _copyFounderDeviceId() async {
    try {
      final deviceId = await FounderDeviceService.instance.getDeviceId();
      await Clipboard.setData(ClipboardData(text: deviceId));
      if (!mounted) return;
      _showSnack('Device ID copied: $deviceId');
    } catch (e) {
      _showSnack('Failed to copy founder device ID: $e');
    }
  }

  Future<void> _checkEventsRoute() async {
    try {
      await BackendApiService.instance.getAdminEvents();
      if (!mounted) return;
      _showSnack('Events admin pipeline is working.');
    } catch (e) {
      _showSnack(_featureErrorMessage(feature: 'events', error: e));
    }
  }

  Future<void> _checkChallengesRoute() async {
    try {
      await BackendApiService.instance.getAdminMissions();
      if (!mounted) return;
      _showSnack('Mission admin pipeline is working.');
    } catch (e) {
      _showSnack(_featureErrorMessage(feature: 'missions', error: e));
    }
  }

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
  final List<Widget>? actions;

  const _AdminSectionHeader({
    required this.title,
    required this.onRefresh,
    this.actions,
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
        if (actions != null) ...actions!,
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

class _SystemActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SystemActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textFor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.text3For(context),
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.text4),
    );
  }
}
