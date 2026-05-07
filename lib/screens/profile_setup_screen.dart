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

  late List<String> _roles;
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
    _roles = user.roles.isNotEmpty ? List<String>.from(user.roles) : [];
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

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _handleCtrl.text.trim().isEmpty ||
          _year.isEmpty ||
          _branch.isEmpty ||
          _roles.isEmpty) {
        setState(() => _error = 'Please fill in all identity fields and select at least one role.');
        return false;
      }
    } else if (_step == 1) {
      if (_buildingCtrl.text.trim().isEmpty || _stack.isEmpty) {
        setState(() => _error = 'Please add what you are building and at least one skill.');
        return false;
      }
      if (_getWordCount(_bioCtrl.text) > 50) {
        setState(() => _error = 'Bio must be under 50 words.');
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
    if (_stack.length >= 5) {
      setState(() => _error = 'Maximum 5 skills allowed.');
      return;
    }
    if (_stack.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _stackCtrl.clear();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _stack = [..._stack, tag];
      _stackCtrl.clear();
      _error = null;
    });
  }

  void _removeStackTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      _stack = _stack.where((item) => item != tag).toList();
    });
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
          handle: _handleCtrl.text.trim(),
          roles: _roles,
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
    final backgroundColor = AppColors.bgFor(context);
    final surfaceColor = AppColors.bg2For(context);
    final elevatedSurfaceColor = AppColors.bg3For(context);
    final borderColor = AppColors.borderFor(context);
    final primaryTextColor = AppColors.textFor(context);
    final secondaryTextColor = AppColors.text2For(context);
    final tertiaryTextColor = AppColors.text3For(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
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
                      backgroundColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: borderColor),
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
                        style: TextStyle(
                          fontSize: 16, // Smaller header
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _subtitle,
                        key: ValueKey(_subtitle),
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                          height: 1.3,
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
                            height: 2, // Thinner step bar
                            margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : elevatedSurfaceColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_step + 1} of 3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: tertiaryTextColor.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
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
              // Sleek Instagram-style bottom bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: OutlinedButton(
                            onPressed: _saving ? null : _back,
                            style: OutlinedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: borderColor),
                            ),
                            child: Icon(Icons.chevron_left_rounded, color: primaryTextColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _next,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
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
                                        ? (_isOnboarding ? 'Finish' : 'Save Changes')
                                        : 'Next Step',
                                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ImageUploadWidget(
                      existingUrl: _avatarPath,
                      uploadPath: 'profiles/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      size: 96,
                      isCircle: true,
                      onUploaded: (url) {
                        HapticFeedback.mediumImpact();
                        setState(() => _avatarPath = url);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Add a profile photo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A clean photo makes your account look real when people see your posts and profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.text3For(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _sectionLabel('NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(hintText: 'Your full name'),
            validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 18),
          _sectionLabel('HANDLE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _handleCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(
              hintText: 'your_handle',
              prefixText: '@ ',
              prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Handle is required' : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('ROLES (MAX 3)'),
              Text(
                '${_roles.length}/3',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _roles.length >= 3 ? AppColors.primary : AppColors.text3For(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return kTechStackOptions.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              if (!_roles.contains(selection) && _roles.length < 3) {
                HapticFeedback.mediumImpact();
                setState(() => _roles.add(selection));
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: AppColors.textFor(context), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search roles (e.g. Frontend, Backend)',
                  hintStyle: TextStyle(color: AppColors.text3For(context), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            options: kProfileRoles,
            selectedValues: _roles,
            maxSelection: 3,
            onChanged: (values) {
              HapticFeedback.selectionClick();
              setState(() {
                _roles = values;
                if (_roles.length <= 3) _error = null;
              });
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('YEAR'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            options: kAcademicYears,
            selectedValues: [_year],
            onChanged: (values) {
              if (values.isNotEmpty) {
                HapticFeedback.selectionClick();
                setState(() => _year = values.first);
              }
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('BRANCH'),
          const SizedBox(height: 10),
          _ChoiceWrap(
            options: kBranches,
            selectedValues: [_branch],
            onChanged: (values) {
              if (values.isNotEmpty) {
                HapticFeedback.selectionClick();
                setState(() => _branch = values.first);
              }
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('COLLEGE'),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return kCollegeOptions;
              }
              return kCollegeOptions.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() => _college = selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text.isEmpty && _college.isNotEmpty) {
                controller.text = _college;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: AppColors.textFor(context), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search or type your college name',
                  hintStyle: TextStyle(color: AppColors.text3For(context), fontSize: 14),
                ),
                onChanged: (value) {
                  setState(() => _college = value);
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  color: AppColors.bg2For(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: TextStyle(color: AppColors.textFor(context), fontSize: 14),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('WHAT ARE YOU BUILDING?'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _buildingCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(
              hintText: 'Ex: Placement prep app, ML attendance system...',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Tell us what you are building' : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('STACK & SKILLS (MAX 5)'),
              Text(
                '${_stack.length}/5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _stack.length >= 5 ? AppColors.primary : AppColors.text3For(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return kTechStackOptions.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _stackCtrl.text = selection;
              _addStackTag();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: AppColors.textFor(context), fontSize: 14),
                onFieldSubmitted: (v) => _addStackTag(),
                decoration: InputDecoration(
                  hintText: 'Search or type skill...',
                  hintStyle: const TextStyle(fontSize: 14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 22),
                    onPressed: _addStackTag,
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  color: AppColors.bg2For(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: TextStyle(color: AppColors.textFor(context), fontSize: 13),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('BIO (MAX 50 WORDS)'),
              Text(
                '${_getWordCount(_bioCtrl.text)}/50 words',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getWordCount(_bioCtrl.text) > 50 ? AppColors.primary : AppColors.text3For(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            style: TextStyle(color: AppColors.textFor(context), height: 1.5),
            onChanged: (v) => setState(() {}),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GITHUB'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _githubCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: InputDecoration(
              hintText: 'github_username',
              prefixText: '@ ',
              prefixStyle: TextStyle(color: AppColors.text3For(context)),
            ),
          ),
          const SizedBox(height: 32),
          _sectionLabel('PREVIEW'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderFor(context)),
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
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textFor(context)),
                          ),
                          Text(
                            '@${_handleCtrl.text.isEmpty ? 'handle' : _handleCtrl.text}',
                            style: TextStyle(fontSize: 13, color: AppColors.text3For(context)),
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
                    _ReviewChip(icon: '🧩', label: _roles.isEmpty ? 'No role' : _roles.join(' · ')),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.borderFor(context)),
                const SizedBox(height: 14),
                Text(
                  'CURRENTLY BUILDING',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text3For(context),
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildingCtrl.text.isEmpty ? 'No project described yet' : _buildingCtrl.text,
                  style: TextStyle(fontSize: 15, color: AppColors.text2For(context), height: 1.4),
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
                                color: AppColors.bg3For(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 12, color: AppColors.text2For(context)),
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
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.text3For(context),
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final int maxSelection;

  const _ChoiceWrap({
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.maxSelection = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final active = selectedValues.contains(option);
        return GestureDetector(
          onTap: () {
            final newValues = List<String>.from(selectedValues);
            if (active) {
              if (maxSelection > 1 || newValues.length > 1) {
                 newValues.remove(option);
              }
            } else {
              if (maxSelection == 1) {
                newValues.clear();
                newValues.add(option);
              } else if (newValues.length < maxSelection) {
                newValues.add(option);
              }
            }
            onChanged(newValues);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.borderFor(context),
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
                color: active ? Colors.white : AppColors.text2For(context),
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
        color: AppColors.bg3For(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderFor(context).withValues(alpha: 0.5)),
      ),
      child: Text(
        '$icon  $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.text2For(context),
        ),
      ),
    );
  }
}
