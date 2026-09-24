import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/enter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../care/data/care_repository.dart';
import '../../priests/data/priest_repository.dart';
import '../data/admin_repository.dart';
import '../domain/admin_scope.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _createMember() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.createMemberAccount),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: name,
                  label: AppStrings.fullName,
                  hint: AppStrings.fullName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: email,
                  label: AppStrings.email,
                  hint: AppStrings.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: password,
                  label: AppStrings.password,
                  hint: AppStrings.password,
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (Validators.required(name.text) != null ||
                    Validators.email(email.text) != null ||
                    Validators.password(password.text) != null) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );
    final fullName = name.text.trim();
    final mail = email.text.trim();
    final pass = password.text;
    name.dispose();
    email.dispose();
    password.dispose();
    if (created != true || !mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .createMemberAccount(
            fullName: fullName,
            email: mail,
            password: pass,
          );
      ref.invalidate(directoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.memberCreated)));
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(authControllerProvider);
    final isSuper = actor?.isSuperAdmin ?? false;
    final members = [
      for (final user in ref.watch(scopedMembersProvider))
        if (matchesMemberQuery(user, _query.text)) user,
    ]..sort((a, b) => a.fullName.compareTo(b.fullName));
    final priests = ref.watch(priestRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backLabel,
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          isSuper ? AppStrings.adminAccounts : AppStrings.adminMembers,
        ),
      ),
      floatingActionButton: isSuper
          ? FloatingActionButton.extended(
              onPressed: _createMember,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(AppStrings.addMemberAccount),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppStrings.searchMembers,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: EmptyState(
                      title: isSuper
                          ? AppStrings.emptyAccounts
                          : AppStrings.emptyMembers,
                      body: isSuper
                          ? AppStrings.emptyAccountsHint
                          : AppStrings.emptyMembersHint,
                      icon: Icons.people_outline,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      100,
                    ),
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final father = member.hasFather
                          ? priests.byId(member.fatherId!)
                          : null;
                      return AppCard(
                        onTap: () =>
                            context.push('/admin/members/${member.id}'),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary50,
                              child: Text(
                                member.firstName.isEmpty
                                    ? '?'
                                    : member.firstName.substring(0, 1),
                                style: const TextStyle(
                                  color: AppColors.primary700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      roleLabelFor(member),
                                      if (member.role.name == 'member')
                                        father?.name ??
                                            AppStrings.noFatherAssigned,
                                      if (member.isSuspended)
                                        AppStrings.memberSuspended,
                                    ].join(' · '),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_left,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ).enter(context, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
