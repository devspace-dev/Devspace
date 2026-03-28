import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

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
    _buildingCtrl.text = user.building == 'Not set' ? '' : user.building;
    _bioCtrl.text = user.bio;
    _githubCtrl.text = user.githubHandle;
    _role = user.role.isNotEmpty ? user.role : kProfileRoles.first;
    _year = user.year;
    _branch = user.branch;
    _college = user.college.isNotEmpty ? user.college : kCollegeOptions.first;
    _stack = List<String>.from(user.stack);
    _avatarPath = user.isImageAvatar ? user.avatar : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _buildingCtrl.dispose();
    _bioCtrl.dispose();
    _githubCtrl.dispose();
    _stackCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _handleCtrl.text.trim().isEmpty ||
          _year.isEmpty ||
          _branch.isEmpty) {
        setState(() => _error = 'Please fill in all identity fields.');
        return false;
      }
    } else if (_step == 1) {
      if (_buildingCtrl.text.trim().isEmpty || _stack.isEmpty) {
        setState(() => _error = 'Please add what you are building and at least one skill.');
        return false;
      }
    }
    setState(() => _error = null);
    return true;
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
    HapticFeedback.lightImpact();
    setState(() {
      _stack = [..._stack, tag];
      _stackCtrl.clear();
    });
  }

  void _removeStackTag(String tag) {
    HapticFeedback.selectionClick();
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
    if (!_validateStep()) return;

    if (_step < 2) {
      HapticFeedback.mediumImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    _submit();
  }

  void _back() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      user.color.withValues(alpha: 0.15),
                      AppColors.bg,
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _title,
                        key: ValueKey(_title),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _subtitle,
                        key: ValueKey(_subtitle),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(3, (index) {
                        final active = index <= _step;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 6,
                            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.bg3,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Step ${_step + 1} of 3',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text3,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _buildStep0(user.id),
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
                          onPressed: _saving ? null : _back,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _next,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _step == 2
                                    ? (_isOnboarding ? 'Finish setup' : 'Save changes')
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
      ),
    );
  }

  Widget _buildStep0(String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                ImageUploadWidget(
                  existingUrl: _avatarPath,
                  uploadPath: 'profiles/$uid.jpg',
                  size: 112,
                  isCircle: true,
                  onUploaded: (url) {
                    HapticFeedback.mediumImpact();
                    setState(() => _avatarPath = url);
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'A professional photo helps you build trust.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.text3),
            ),
          ),
          const SizedBox(height: 32),
          _sectionLabel('NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Your full name'),
            validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 18),
          _sectionLabel('HANDLE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _handleCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'your_handle',
              prefixText: '@ ',
              prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Handle is required' : null,
          ),
          const SizedBox(height: 20),
          _sectionLabel('ROLE'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            options: kProfileRoles,
            value: _role,
            onSelected: (value) {
              HapticFeedback.selectionClick();
              setState(() => _role = value);
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('YEAR'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            options: kAcademicYears,
            value: _year,
            onSelected: (value) {
              HapticFeedback.selectionClick();
              setState(() => _year = value);
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('BRANCH'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            options: kBranches,
            value: _branch,
            onSelected: (value) {
              HapticFeedback.selectionClick();
              setState(() => _branch = value);
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('COLLEGE'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: kCollegeOptions.contains(_college) ? _college : kCollegeOptions.first,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
            items: kCollegeOptions
                .map((college) => DropdownMenuItem<String>(
                      value: college,
                      child: Text(college, style: const TextStyle(fontSize: 14)),
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
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('WHAT ARE YOU BUILDING?'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _buildingCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'Ex: Placement prep app, ML attendance system...',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Tell us what you are building' : null,
          ),
          const SizedBox(height: 24),
          _sectionLabel('STACK & SKILLS'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _stackCtrl,
            style: const TextStyle(color: AppColors.text),
            onFieldSubmitted: (_) => _addStackTag(),
            decoration: InputDecoration(
              hintText: 'Add a skill, then tap +',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                onPressed: _addStackTag,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_stack.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _stack
                  .map(
                    (tag) => GestureDetector(
                      onTap: () => _removeStackTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 28),
          _sectionLabel('BIO'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            style: const TextStyle(color: AppColors.text, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'What do you like building? What do you want people to know about you?',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GITHUB'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _githubCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'github_username',
              prefixText: '@ ',
              prefixStyle: TextStyle(color: AppColors.text3),
            ),
          ),
          const SizedBox(height: 32),
          _sectionLabel('PREVIEW'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text),
                          ),
                          Text(
                            '@${_handleCtrl.text.isEmpty ? 'handle' : _handleCtrl.text}',
                            style: const TextStyle(fontSize: 13, color: AppColors.text3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _ReviewChip(icon: '🎓', label: _college),
                    _ReviewChip(icon: '📍', label: '$_year · $_branch'),
                    _ReviewChip(icon: '🧩', label: _role),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 14),
                const Text(
                  'CURRENTLY BUILDING',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text3,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildingCtrl.text.isEmpty ? 'No project described yet' : _buildingCtrl.text,
                  style: const TextStyle(fontSize: 15, color: AppColors.text2, height: 1.4),
                ),
                if (_stack.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _stack
                        .take(5)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.bg3,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(fontSize: 12, color: AppColors.text2),
                              ),
                            ))
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.text3,
        letterSpacing: 1.2,
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
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
        color: AppColors.bg3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
