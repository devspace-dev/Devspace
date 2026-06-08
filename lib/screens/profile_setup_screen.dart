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

  final _nameCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
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
  int get _totalSteps => _isOnboarding ? 2 : 3;
  bool get _isLastStep => _step == _totalSteps - 1;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl.text = user.name;
    _handleCtrl.text = user.handle;
    _college = user.college.isNotEmpty ? user.college : kCollegeOptions.first;
    _collegeCtrl.text = _college;
    _buildingCtrl.text = user.building == 'Not set' ? '' : user.building;
    _bioCtrl.text = user.bio;
    _githubCtrl.text = user.githubHandle;
    _roles = user.roles.isNotEmpty ? List<String>.from(user.roles) : ['Student'];
    _year = user.year;
    _branch = user.branch;
    _stack = List<String>.from(user.stack);
    _avatarPath = user.isImageAvatar ? user.avatar : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _collegeCtrl.dispose();
    _buildingCtrl.dispose();
    _bioCtrl.dispose();
    _githubCtrl.dispose();
    _stackCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (_isOnboarding) {
      return _step == 0 ? 'Create your profile' : 'Add builder details';
    }
    return _step == 0
        ? 'Public basics'
        : _step == 1
            ? 'Builder details'
            : 'Photo and links';
  }

  String get _subtitle {
    if (_isOnboarding) {
      return _step == 0
          ? 'Only the basics are required before entering DevSpace.'
          : 'This is optional. You can finish now and edit later.';
    }
    return 'Keep your student builder profile current and easy to scan.';
  }

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  bool _validateBasics() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name is required.');
      return false;
    }
    if (_handleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Handle is required.');
      return false;
    }
    if (_collegeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'College is required.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateCurrentStep() {
    if (_step == 0) return _validateBasics();
    if (_wordCount(_bioCtrl.text) > 50) {
      setState(() => _error = 'Bio must be under 50 words.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _submit({bool skipOptional = false}) async {
    if (!_validateBasics()) return;
    if (!skipOptional && !_validateCurrentStep()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final roles = _roles.isEmpty ? const ['Student'] : _roles;
    final result = await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
          handle: _handleCtrl.text.trim(),
          roles: roles,
          year: _year,
          branch: _branch,
          building: _buildingCtrl.text.trim(),
          stack: _stack,
          college: _collegeCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          githubHandle: _githubCtrl.text.trim(),
          avatar: _avatarPath,
        );

    if (!mounted) return;

    if (result.success) {
      if (_isOnboarding) {
        setState(() => _saving = false);
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_isLastStep) {
      _submit();
      return;
    }

    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _addStackTag([String? value]) {
    final tag = (value ?? _stackCtrl.text).trim();
    if (tag.isEmpty) return;
    if (_stack.length >= 5) {
      setState(() => _error = 'Maximum 5 skills allowed.');
      return;
    }
    if (_stack.any((item) => item.toLowerCase() == tag.toLowerCase())) {
      _stackCtrl.clear();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _stack = [..._stack, tag];
      _stackCtrl.clear();
      _error = null;
    });
  }

  void _removeStackTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() => _stack = _stack.where((item) => item != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final border = AppColors.borderFor(context);
    final text = AppColors.textFor(context);
    final text2 = AppColors.text2For(context);
    final text3 = AppColors.text3For(context);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _isOnboarding
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: text),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text(_isOnboarding ? 'Profile setup' : 'Edit profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    style: TextStyle(fontSize: 13, height: 1.4, color: text2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(_totalSteps, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: 3,
                          margin: EdgeInsets.only(
                            right: index == _totalSteps - 1 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? user.color
                                : AppColors.bg3For(context),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_step + 1} of $_totalSteps',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: text3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _step = value),
                children: _isOnboarding
                    ? [_buildBasicsStep(), _buildBuilderStep()]
                    : [_buildBasicsStep(), _buildBuilderStep(), _buildExtrasStep(user.id)],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Icon(Icons.chevron_left_rounded, color: text),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (_isOnboarding && _step == 1) ...[
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(skipOptional: true),
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _next,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                                _isLastStep
                                    ? (_isOnboarding ? 'Enter DevSpace' : 'Save')
                                    : 'Continue',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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

  Widget _buildBasicsStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        _FieldBlock(
          label: 'Name',
          child: TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(hintText: 'Your full name'),
          ),
        ),
        _FieldBlock(
          label: 'Handle',
          child: TextField(
            controller: _handleCtrl,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(
              hintText: 'your_handle',
              prefixText: '@ ',
            ),
          ),
        ),
        _FieldBlock(
          label: 'College',
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: _collegeCtrl.text),
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return kCollegeOptions;
              return kCollegeOptions.where(
                (option) => option.toLowerCase().contains(query),
              );
            },
            onSelected: (selection) {
              _collegeCtrl.text = selection;
              setState(() => _college = selection);
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              if (controller.text.isEmpty && _collegeCtrl.text.isNotEmpty) {
                controller.text = _collegeCtrl.text;
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: AppColors.textFor(context)),
                decoration: const InputDecoration(
                  hintText: 'Search or type your college',
                ),
                onChanged: (value) {
                  _collegeCtrl.text = value;
                  _college = value;
                },
              );
            },
            optionsViewBuilder: _optionsViewBuilder,
          ),
        ),
        if (_isOnboarding)
          _SoftNote(
            icon: Icons.lock_open_rounded,
            title: 'No long form before the app',
            message:
                'You can start with these basics. Add projects, skills, GitHub, and photo later from Profile.',
          ),
      ],
    );
  }

  Widget _buildBuilderStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        _FieldBlock(
          label: 'Year',
          child: _ChoiceWrap(
            options: kAcademicYears,
            selectedValues: _year.isEmpty ? const [] : [_year],
            onChanged: (values) {
              HapticFeedback.selectionClick();
              setState(() => _year = values.isEmpty ? '' : values.first);
            },
          ),
        ),
        _FieldBlock(
          label: 'Branch',
          child: _ChoiceWrap(
            options: kBranches,
            selectedValues: _branch.isEmpty ? const [] : [_branch],
            onChanged: (values) {
              HapticFeedback.selectionClick();
              setState(() => _branch = values.isEmpty ? '' : values.first);
            },
          ),
        ),
        _FieldBlock(
          label: 'Role',
          child: _ChoiceWrap(
            options: kProfileRoles,
            selectedValues: _roles,
            maxSelection: 2,
            onChanged: (values) {
              HapticFeedback.selectionClick();
              setState(() => _roles = values);
            },
          ),
        ),
        _FieldBlock(
          label: 'Currently building',
          child: TextField(
            controller: _buildingCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(
              hintText: 'Optional: placement app, portfolio, ML project...',
            ),
          ),
        ),
        _FieldBlock(
          label: 'Skills',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return const Iterable<String>.empty();
                  return kTechStackOptions.where(
                    (option) => option.toLowerCase().contains(query),
                  );
                },
                onSelected: (selection) {
                  _addStackTag(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (value) => _stackCtrl.text = value,
                    onSubmitted: (value) => _addStackTag(value),
                    style: TextStyle(color: AppColors.textFor(context)),
                    decoration: InputDecoration(
                      hintText: 'Optional: Flutter, React, Python...',
                      suffixIcon: IconButton(
                        onPressed: () => _addStackTag(controller.text),
                        icon: const Icon(Icons.add_circle_rounded),
                      ),
                    ),
                  );
                },
                optionsViewBuilder: _optionsViewBuilder,
              ),
              if (_stack.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _stack
                      .map(
                        (tag) => InputChip(
                          label: Text(tag),
                          onDeleted: () => _removeStackTag(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtrasStep(String uid) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Center(
          child: ImageUploadWidget(
            existingUrl: _avatarPath,
            uploadPath: 'profiles/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            size: 92,
            isCircle: true,
            onUploaded: (url) {
              HapticFeedback.mediumImpact();
              setState(() => _avatarPath = url);
            },
          ),
        ),
        const SizedBox(height: 22),
        _FieldBlock(
          label: 'Bio',
          trailing: '${_wordCount(_bioCtrl.text)}/50 words',
          child: TextField(
            controller: _bioCtrl,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppColors.textFor(context), height: 1.4),
            decoration: const InputDecoration(
              hintText: 'Optional: what do you like building?',
            ),
          ),
        ),
        _FieldBlock(
          label: 'GitHub',
          child: TextField(
            controller: _githubCtrl,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: const InputDecoration(
              hintText: 'github_username',
              prefixText: '@ ',
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionsViewBuilder(
    BuildContext context,
    AutocompleteOnSelected<String> onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: AppColors.bg2For(context),
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 220,
            maxWidth: MediaQuery.sizeOf(context).width - 40,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                dense: true,
                title: Text(
                  option,
                  style: TextStyle(color: AppColors.textFor(context)),
                ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final String? trailing;
  final Widget child;

  const _FieldBlock({
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text3For(context),
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3For(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SoftNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SoftNote({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.text2For(context),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        return ChoiceChip(
          label: Text(option),
          selected: active,
          onSelected: (_) {
            final values = List<String>.from(selectedValues);
            if (active) {
              values.remove(option);
            } else if (maxSelection == 1) {
              values
                ..clear()
                ..add(option);
            } else if (values.length < maxSelection) {
              values.add(option);
            }
            onChanged(values);
          },
        );
      }).toList(),
    );
  }
}
