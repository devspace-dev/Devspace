import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/profile_card.dart';
import 'profile_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  String _branch    = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersP = context.watch<UsersProvider>();
    var users = usersP.search(_query);
    if (_branch != 'All') {
      users = users.where((u) => u.branch == _branch).toList();
    }
    final hasSearchOrFilter = _query.isNotEmpty || _branch != 'All';

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppColors.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search developers, stacks, projects...',
              prefixIcon: const Icon(Icons.search, color: AppColors.text3, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close, color: AppColors.text3, size: 18),
                    )
                  : null,
            ),
          ),
        ),

        // Branch filter chips
        Container(
          height: 46,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: kBranchFilters.map((f) {
              final active = _branch == f;
              return GestureDetector(
                onTap: () => setState(() => _branch = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.bg3,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.text3,
                      )),
                ),
              );
            }).toList(),
          ),
        ),

        // User list
        Expanded(
          child: usersP.isLoading && usersP.users.isEmpty
              ? const AppLoadingState(
                  title: 'Loading developers',
                  message:
                      'Pulling in student builders and their latest profiles.',
                )
              : usersP.error != null && usersP.users.isEmpty
              ? AppErrorState(
                  title: 'Developers unavailable',
                  message: usersP.error!,
                  actionLabel: 'Retry',
                  onAction: () {
                    usersP.refreshUsers();
                  },
                )
              : usersP.users.isEmpty
              ? const AppEmptyState(
                  icon: Icons.groups_rounded,
                  title: 'No developers yet',
                  message:
                      'Once students join DevSpace, their profiles will show up here.',
                )
              : users.isEmpty
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: hasSearchOrFilter
                      ? 'No matching developers'
                      : 'No developers found',
                  message: hasSearchOrFilter
                      ? 'Try another name, branch, or stack keyword.'
                      : 'No developer profiles are available yet.',
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) => ProfileCard(
                    user: users[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: users[i].id)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
