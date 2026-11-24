import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_card.dart';
import '../providers/auth_provider.dart';
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
      return _step == 0 ? 'CREATE YOUR PROFILE' : 'BUILDER DETAILS';
    }
    return _step == 0
        ? 'PUBLIC BASICS'
        : _step == 1
            ? 'BUILDER DETAILS'
            : 'PHOTO & LINKS';
  }

  String get _subtitle {
    if (_isOnboarding) {
      return _step == 0
          ? 'Only the basics are required before entering DevSpace.'
          : 'Optional details. You can finish now and update later.';
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
    final handle = _handleCtrl.text.trim();
    if (handle.isEmpty) {
      setState(() => _error = 'Handle is required.');
      return false;
    }
    if (handle.length < 3 || handle.length > 25) {
      setState(() => _error = 'Handle must be between 3 and 25 characters.');
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

  InputDecoration _inputDeco({String? hintText, String? prefixText, Widget? suffixIcon}) {
    const surfaceAlt = Color(0xFF1E2030);
    return InputDecoration(
      filled: true,
      fillColor: surfaceAlt,
      hintText: hintText,
      hintStyle: DsText.body.copyWith(color: Ds.muted, fontSize: 14),
      prefixText: prefixText,
      prefixStyle: DsText.label.copyWith(color: Ds.aura),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Ds.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Ds.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Ds.aura, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Ds.bone),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text(
          _isOnboarding ? 'PROFILE SETUP' : 'EDIT PROFILE',
          style: DsText.h3.copyWith(fontSize: 18, color: Ds.bone),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: DsText.h2.copyWith(
                      color: Ds.bone,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    style: DsText.caption.copyWith(
                      color: Ds.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(_totalSteps, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index == _totalSteps - 1 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: active ? Ds.aura : Ds.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'STEP ${_step + 1} OF $_totalSteps',
                    style: DsText.label.copyWith(
                      fontSize: 11,
                      color: Ds.muted,
                      letterSpacing: 1.0,
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
                    color: Ds.hot.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Ds.hot.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _error!,
                    style: DsText.caption.copyWith(
                      color: Ds.hot,
                      fontWeight: FontWeight.w700,
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
                      height: 52,
                      width: 52,
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Ds.border, width: 1.2),
                          backgroundColor: const Color(0xFF1E2030),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Ds.bone, size: 28),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (_isOnboarding && _step == 1) ...[
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(skipOptional: true),
                      child: Text(
                        'SKIP',
                        style: DsText.label.copyWith(
                          color: Ds.muted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: DsButton(
                      label: _isLastStep
                          ? (_isOnboarding ? 'ENTER DEVSPACE' : 'SAVE')
                          : 'CONTINUE',
                      kind: DsButtonKind.aura,
                      loading: _saving,
                      onPressed: _saving ? null : _next,
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
          label: 'NAME',
          child: TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            style: DsText.body.copyWith(color: Ds.bone),
            decoration: _inputDeco(hintText: 'Your full name'),
          ),
        ),
        _FieldBlock(
          label: 'HANDLE',
          child: TextField(
            controller: _handleCtrl,
            textInputAction: TextInputAction.next,
            style: DsText.body.copyWith(color: Ds.bone),
            decoration: _inputDeco(
              hintText: 'your_handle',
              prefixText: '@ ',
            ),
          ),
        ),
        _FieldBlock(
          label: 'COLLEGE',
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
                style: DsText.body.copyWith(color: Ds.bone),
                decoration: _inputDeco(
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
        if (_isOnboarding) ...[
          const SizedBox(height: 10),
          const _SoftNote(
            icon: Icons.flash_on_rounded,
            title: 'NO LONG FORMS BEFORE THE APP',
            message:
                'You can start with these basics. Add projects, skills, GitHub, and photo later from your profile.',
          ),
        ],
      ],
    );
  }

  Widget _buildBuilderStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        _FieldBlock(
          label: 'YEAR',
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
          label: 'BRANCH',
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
          label: 'ROLE',
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
          label: 'SKILLS',
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
                    style: DsText.body.copyWith(color: Ds.bone),
                    decoration: _inputDeco(
                      hintText: 'Optional: Flutter, React, Python...',
                      suffixIcon: IconButton(
                        onPressed: () => _addStackTag(controller.text),
                        icon: const Icon(Icons.add_circle_rounded, color: Ds.aura),
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
                        (tag) => Chip(
                          label: Text(tag, style: DsText.caption.copyWith(color: Ds.bone)),
                          backgroundColor: const Color(0xFF1E2030),
                          deleteIcon: const Icon(Icons.close, size: 16, color: Ds.muted),
                          onDeleted: () => _removeStackTag(tag),
                          side: const BorderSide(color: Ds.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
            uploadPath: 'profiles/${uid}.${DateTime.now().millisecondsSinceEpoch}.jpg',
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
          label: 'BIO',
          trailing: '${_wordCount(_bioCtrl.text)}/50 words',
          child: TextField(
            controller: _bioCtrl,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: DsText.body.copyWith(color: Ds.bone, height: 1.4),
            decoration: _inputDeco(
              hintText: 'Optional: what do you like building?',
            ),
          ),
        ),
        _FieldBlock(
          label: 'GITHUB',
          child: TextField(
            controller: _githubCtrl,
            style: DsText.body.copyWith(color: Ds.bone),
            decoration: _inputDeco(
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
        color: const Color(0xFF1E2030),
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Ds.border, width: 1.2),
          ),
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
                  style: DsText.body.copyWith(color: Ds.bone, fontSize: 13),
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
                style: DsText.label.copyWith(
                  fontSize: 11,
                  color: Ds.muted,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: DsText.caption.copyWith(
                    fontSize: 11,
                    color: Ds.muted,
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
    return DsCard(
      leftBar: Ds.aura,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Ds.aura, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DsText.label.copyWith(
                    fontSize: 12,
                    color: Ds.bone,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: DsText.caption.copyWith(
                    color: Ds.muted,
                    height: 1.35,
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
          label: Text(
            option,
            style: DsText.label.copyWith(
              fontSize: 12,
              color: active ? Ds.onAura : Ds.bone,
            ),
          ),
          selected: active,
          selectedColor: Ds.aura,
          backgroundColor: const Color(0xFF1E2030),
          side: BorderSide(
            color: active ? Ds.aura : Ds.border,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          showCheckmark: false,
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
