import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/image_upload_widget.dart';

enum ProfileSetupMode { onboarding, edit }

class ProfileSetupScreen extends StatefulWidget {
  final ProfileSetupMode mode;

  const ProfileSetupScreen({
    super.key,
    required this.mode,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _stackCtrl = TextEditingController();

  int _step = 0;
  bool _saving = false;
  String? _error;
  String? _avatarPath;

  late String _role;
  late String _year;
  late String _branch;
  late String _college;
  late List<String> _stack;

  bool get _isOnboarding => widget.mode == ProfileSetupMode.onboarding;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl.text = user.name;
    _handleCtrl.text = user.handle;
    _buildingCtrl.text =
        user.building == 'Not set' ? '' : user.building;
    _bioCtrl.text = user.bio;
    _githubCtrl.text = user.githubHandle;
    _role = user.role.isNotEmpty ? user.role : kProfileRoles.first;
    _year = user.year;
    _branch = user.branch;
    _college = user.college.isNotEmpty
        ? user.college
        : kCollegeOptions.first;
    _stack = List<String>.from(user.stack);
    _avatarPath = user.hasImageAvatar ? user.avatar : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _buildingCtrl.dispose();
    _bioCtrl.dispose();
    _githubCtrl.dispose();
    _stackCtrl.dispose();
    super.dispose();
  }

  bool get _isIdentityValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _handleCtrl.text.trim().isNotEmpty &&
      _role.isNotEmpty &&
      _year.isNotEmpty &&
      _branch.isNotEmpty &&
      _college.isNotEmpty;

  bool get _isBuilderValid =>
      _buildingCtrl.text.trim().isNotEmpty && _stack.isNotEmpty;

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _isIdentityValid;
      case 1:
        return _isBuilderValid;
      case 2:
        return true;
      default:
        return false;
    }
  }

  String get _title {
    if (_isOnboarding) {
      return _step == 0
          ? 'Set up your builder identity'
          : _step == 1
              ? 'Show what you are building'
              : 'Add your proof points';
    }
    return _step == 0
        ? 'Edit your profile'
        : _step == 1
            ? 'Update your builder profile'
            : 'Refresh your public details';
  }

  String get _subtitle {
    if (_step == 0) {
      return 'Make your profile recognizable when students discover you.';
    }
    if (_step == 1) {
      return 'Good profiles make the feed and People tab much more valuable.';
    }
    return 'Avatar and GitHub are optional, but they make profiles feel real.';
  }

  void _addStackTag() {
    final tag = _stackCtrl.text.trim();
    if (tag.isEmpty) return;
    if (_stack.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _stackCtrl.clear();
      return;
    }
    setState(() {
      _stack = [..._stack, tag];
      _stackCtrl.clear();
    });
  }

  void _removeStackTag(String tag) {
    setState(() {
      _stack = _stack.where((item) => item != tag).toList();
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
          handle: _handleCtrl.text.trim(),
          role: _role,
          year: _year,
          branch: _branch,
          building: _buildingCtrl.text.trim(),
          stack: _stack,
          college: _college,
          bio: _bioCtrl.text.trim(),
          githubHandle: _githubCtrl.text.trim(),
          avatar: _avatarPath,
        );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  void _next() {
    if (_step < 2) {
      setState(() {
        _error = null;
        _step += 1;
      });
      return;
    }
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isOnboarding ? 'Complete Profile' : 'Edit Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    user.color.withValues(alpha: 0.28),
                    AppColors.bg2,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(3, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.bg3,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Step ${_step + 1} of 3',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _buildStep(user.id),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _error = null;
                                  _step -= 1;
                                }),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_saving || !_canContinue) ? null : _next,
                      child: Text(
                        _saving
                            ? 'Saving...'
                            : _step == 2
                                ? (_isOnboarding
                                    ? 'Finish setup'
                                    : 'Save changes')
                                : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String uid) {
    switch (_step) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('identity-step'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ImageUploadWidget(
                  existingUrl: _avatarPath,
                  uploadPath: 'profile_photos/$uid.jpg',
                  size: 112,
                  isCircle: true,
                  onUploaded: (url) => setState(() => _avatarPath = url),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Add a photo if you want. You can skip it and keep your initials too.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.text3),
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Your full name',
                ),
              ),
              const SizedBox(height: 16),
              _sectionLabel('HANDLE'),
              const SizedBox(height: 8),
              TextField(
                controller: _handleCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'your_handle',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 16),
              _sectionLabel('ROLE'),
              const SizedBox(height: 10),
              _ChoiceWrap(
                options: kProfileRoles,
                value: _role,
                onSelected: (value) => setState(() => _role = value),
              ),
              const SizedBox(height: 18),
              _sectionLabel('YEAR'),
              const SizedBox(height: 10),
              _ChoiceWrap(
                options: kAcademicYears,
                value: _year,
                onSelected: (value) => setState(() => _year = value),
              ),
              const SizedBox(height: 18),
              _sectionLabel('BRANCH'),
              const SizedBox(height: 10),
              _ChoiceWrap(
                options: kBranches,
                value: _branch,
                onSelected: (value) => setState(() => _branch = value),
              ),
              const SizedBox(height: 18),
              _sectionLabel('COLLEGE'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: kCollegeOptions.contains(_college)
                    ? _college
                    : kCollegeOptions.first,
                items: kCollegeOptions
                    .map((college) => DropdownMenuItem<String>(
                          value: college,
                          child: Text(college),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _college = value);
                },
              ),
            ],
          ),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('builder-step'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('WHAT ARE YOU BUILDING?'),
              const SizedBox(height: 8),
              TextField(
                controller: _buildingCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ex: Placement prep app, ML attendance system...',
                ),
              ),
              const SizedBox(height: 18),
              _sectionLabel('STACK'),
              const SizedBox(height: 8),
              TextField(
                controller: _stackCtrl,
                onSubmitted: (_) => _addStackTag(),
                decoration: InputDecoration(
                  hintText: 'Add a skill or tool, then tap +',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _addStackTag,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_stack.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _stack
                      .map(
                        (tag) => GestureDetector(
                          onTap: () => _removeStackTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '$tag  ×',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              _sectionLabel('BIO'),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'What do you like building? What do you want people to know?',
                ),
              ),
            ],
          ),
        );
      case 2:
      default:
        return KeyedSubtree(
          key: const ValueKey('proof-step'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('GITHUB HANDLE'),
              const SizedBox(height: 8),
              TextField(
                controller: _githubCtrl,
                decoration: const InputDecoration(
                  hintText: 'github username',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text3,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameCtrl.text.trim().isEmpty ? 'Your name' : _nameCtrl.text.trim(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_handleCtrl.text.trim().isEmpty ? 'your_handle' : _handleCtrl.text.trim()}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _ReviewChip(icon: '🎓', label: _college),
                        _ReviewChip(icon: '📍', label: '$_year · $_branch'),
                        _ReviewChip(icon: '🧩', label: _role),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _buildingCtrl.text.trim().isEmpty
                          ? 'No current project added'
                          : _buildingCtrl.text.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text2,
                        height: 1.5,
                      ),
                    ),
                    if (_stack.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _stack
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bg3,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.text3,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onSelected;

  const _ChoiceWrap({
    required this.options,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final active = option == value;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.bg3,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.text2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  final String icon;
  final String label;

  const _ReviewChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$icon  $label',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.text2,
        ),
      ),
    );
  }
}
