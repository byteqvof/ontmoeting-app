import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/activity_attendance_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/safety_service.dart';
import '../../../../core/widgets/safety_report_dialog.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/complete_activity.dart';
import '../../domain/usecases/set_activity_participation.dart';
import '../../domain/usecases/submit_activity_feedback.dart';
import '../widgets/activity_detail_action_bar.dart';
import '../widgets/activity_detail_hero.dart';
import '../widgets/activity_detail_host_card.dart';
import '../widgets/activity_detail_info_card.dart';
import '../widgets/activity_detail_participants_card.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({required this.activity, super.key});

  final HomeActivity activity;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late HomeActivity _activity = widget.activity;
  final SetActivityParticipation _setActivityParticipation = sl();
  final CompleteActivity _completeActivityUseCase = sl();
  final SubmitActivityFeedback _submitActivityFeedback = sl();
  final ActivityAttendanceService _attendanceService = sl();
  final SafetyService _safetyService = sl();
  bool _isParticipationPending = false;
  bool _isCompletionPending = false;
  bool _isFeedbackPending = false;
  final Set<String> _attendancePendingIds = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(
      'activity_viewed',
      properties: {
        'status': _activity.status,
        'is_joined': _activity.isJoined,
        'is_owned': _activity.isOwnedByCurrentUser,
        'requires_identity_verified': _activity.requiresIdentityVerified,
        'group_type': _activity.groupType,
      },
    );
  }

  Future<void> _toggleParticipation() async {
    if (_activity.isOwnedByCurrentUser || _isParticipationPending) {
      return;
    }

    if (!_activity.isJoined && _activity.availableSpots <= 0) {
      _showMessage('Deze activiteit zit vol.');
      return;
    }

    setState(() {
      _isParticipationPending = true;
    });

    final wasJoining = !_activity.isJoined;
    final result = await _setActivityParticipation(
      SetActivityParticipationParams(
        activityId: _activity.id,
        join: wasJoining,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isParticipationPending = false;
        });
        _showMessage(failure.message);
      },
      (update) {
        final updatedActivity = _activity.applyParticipationUpdate(update);
        setState(() {
          _activity = updatedActivity;
          _isParticipationPending = false;
        });
        if (wasJoining && updatedActivity.isJoined) {
          context.push(
            AppRoutes.activityJoinConfirmationPath(updatedActivity.id),
            extra: updatedActivity,
          );
        }
      },
    );
  }

  Future<void> _completeActivity() async {
    if (!_activity.isOwnedByCurrentUser ||
        _activity.isCompleted ||
        _isCompletionPending) {
      return;
    }

    setState(() {
      _isCompletionPending = true;
    });

    final result = await _completeActivityUseCase(
      CompleteActivityParams(activityId: _activity.id),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isCompletionPending = false;
        });
        _showMessage(failure.message);
      },
      (update) {
        setState(() {
          _activity = _activity.applyCompletionUpdate(update);
          _isCompletionPending = false;
        });
        _showMessage('Activiteit afgerond.');
      },
    );
  }

  Future<void> _submitFeedback({
    required _FeedbackTarget target,
    required int rating,
    required String comment,
  }) async {
    if (_isFeedbackPending) {
      return;
    }

    setState(() {
      _isFeedbackPending = true;
    });

    final result = await _submitActivityFeedback(
      SubmitActivityFeedbackParams(
        activityId: _activity.id,
        targetProfileId: target.id,
        rating: rating,
        comment: comment,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isFeedbackPending = false;
        });
        _showMessage(failure.message);
      },
      (_) {
        setState(() {
          _activity = _activityWithSubmittedFeedback(_activity, target.id);
          _isFeedbackPending = false;
        });
        _showMessage('Feedback opgeslagen voor ${target.name}.');
      },
    );
  }

  Future<void> _markAttendance({
    required _FeedbackTarget target,
    required ActivityAttendanceStatus status,
  }) async {
    if (_attendancePendingIds.contains(target.id)) {
      return;
    }

    setState(() {
      _attendancePendingIds.add(target.id);
    });

    try {
      await _attendanceService.markAttendance(
        activityId: _activity.id,
        profileId: target.id,
        status: status,
      );
      if (mounted) {
        setState(() {
          _activity = _activityWithAttendance(
            _activity,
            target.id,
            status.backendValue,
          );
        });
        _showMessage(switch (status) {
          ActivityAttendanceStatus.present =>
            '${target.name} gemarkeerd als aanwezig.',
          ActivityAttendanceStatus.absent =>
            '${target.name} gemarkeerd als niet aanwezig.',
          ActivityAttendanceStatus.unknown =>
            '${target.name} gemarkeerd als onbekend.',
        });
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Aanwezigheid bijwerken lukt nu niet.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _attendancePendingIds.remove(target.id);
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openChat() {
    if (!_activity.isOwnedByCurrentUser && !_activity.isJoined) {
      _showMessage('Meld je eerst aan om de chat te openen.');
      return;
    }

    context.push(AppRoutes.activityChatPath(_activity.id), extra: _activity);
  }

  Future<void> _reportActivity() async {
    final report = await _askForSafetyDetails(
      context,
      title: 'Activiteit rapporteren',
      body: 'Vertel kort wat er niet klopt.',
      confirmLabel: 'Rapporteer',
    );
    if (report == null || !mounted) {
      return;
    }

    try {
      await _safetyService.reportActivity(
        activityId: _activity.id,
        reason: report.reason,
        details: report.details,
      );
      if (mounted) {
        _showMessage('Activiteit gerapporteerd.');
      }
      AnalyticsService.instance.track(
        'report_submitted',
        properties: {'target_type': 'activity', 'reason': report.reason.name},
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Rapporteren lukt nu niet.');
      }
    }
  }

  Future<void> _editActivity() async {
    final updated = await context.push<HomeActivity>(
      AppRoutes.editActivityPath(_activity.id),
      extra: _activity,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _activity = updated;
    });
    _showMessage('Activiteit bijgewerkt.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _goBack(context);
      },
      child: Scaffold(
        backgroundColor: colors.cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ActivityDetailHero(
                        activity: _activity,
                        onBackPressed: () => _goBack(context),
                        onEditPressed:
                            _activity.isOwnedByCurrentUser &&
                                !_activity.isCompleted
                            ? _editActivity
                            : null,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 126),
                      sliver: SliverList.list(
                        children: [
                          ActivityDetailInfoCard(activity: _activity),
                          const SizedBox(height: TochSpacing.md),
                          ActivityDetailHostCard(
                            activity: _activity,
                            onProfilePressed: (profileId) {
                              context.push(AppRoutes.profilePath(profileId));
                            },
                          ),
                          const SizedBox(height: TochSpacing.md),
                          _DescriptionCard(activity: _activity),
                          const SizedBox(height: TochSpacing.md),
                          ActivityDetailParticipantsCard(
                            activity: _activity,
                            onProfilePressed: (profileId) {
                              context.push(AppRoutes.profilePath(profileId));
                            },
                          ),
                          if (_activity.isCompleted) ...[
                            if (_activity.isOwnedByCurrentUser) ...[
                              const SizedBox(height: TochSpacing.md),
                              _AttendanceCard(
                                activity: _activity,
                                pendingProfileIds: _attendancePendingIds,
                                onMarkAttendance: _markAttendance,
                              ),
                            ],
                            const SizedBox(height: TochSpacing.md),
                            _FeedbackCard(
                              activity: _activity,
                              isSubmitting: _isFeedbackPending,
                              onSubmit: _submitFeedback,
                            ),
                          ],
                          const SizedBox(height: TochSpacing.md),
                          _SafetyCard(
                            canReport: !_activity.isOwnedByCurrentUser,
                            onReportPressed: _reportActivity,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ActivityDetailActionBar(
                    activity: _activity,
                    isParticipationPending: _isParticipationPending,
                    isCompletionPending: _isCompletionPending,
                    onParticipationPressed: _toggleParticipation,
                    onCompletePressed: _completeActivity,
                    onChatPressed: _openChat,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop(_activity);
      return;
    }
    context.go(AppRoutes.home);
  }
}

class _FeedbackTarget {
  const _FeedbackTarget({
    required this.id,
    required this.name,
    required this.initials,
    this.avatarUrl,
    this.attendanceStatus,
    this.feedbackSubmitted = false,
  });

  final String id;
  final String name;
  final String initials;
  final String? avatarUrl;
  final String? attendanceStatus;
  final bool feedbackSubmitted;
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.activity,
    required this.pendingProfileIds,
    required this.onMarkAttendance,
  });

  final HomeActivity activity;
  final Set<String> pendingProfileIds;
  final Future<void> Function({
    required _FeedbackTarget target,
    required ActivityAttendanceStatus status,
  })
  onMarkAttendance;

  List<_FeedbackTarget> get _targets {
    return activity.participants
        .where((participant) => participant.id.isNotEmpty)
        .map(
          (participant) => _FeedbackTarget(
            id: participant.id,
            name: participant.displayName,
            initials: participant.initials,
            avatarUrl: participant.avatarUrl,
            attendanceStatus: participant.attendanceStatus,
            feedbackSubmitted: participant.feedbackSubmitted,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final targets = _targets;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opkomst',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .7),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.xs),
            Text(
              'Markeer wie erbij was. Dit telt mee voor reputatie.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.green700.withValues(alpha: .72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            if (targets.isEmpty)
              Text(
                'Er zijn nog geen deelnemers om te markeren.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final target in targets) ...[
                _AttendanceRow(
                  target: target,
                  isPending: pendingProfileIds.contains(target.id),
                  selectedStatus: target.attendanceStatus,
                  onPresent: () => onMarkAttendance(
                    target: target,
                    status: ActivityAttendanceStatus.present,
                  ),
                  onAbsent: () => onMarkAttendance(
                    target: target,
                    status: ActivityAttendanceStatus.absent,
                  ),
                  onUnknown: () => onMarkAttendance(
                    target: target,
                    status: ActivityAttendanceStatus.unknown,
                  ),
                ),
                if (target != targets.last)
                  Divider(height: TochSpacing.md, color: colors.line),
              ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.target,
    required this.isPending,
    required this.selectedStatus,
    required this.onPresent,
    required this.onAbsent,
    required this.onUnknown,
  });

  final _FeedbackTarget target;
  final bool isPending;
  final String? selectedStatus;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.green100,
          foregroundColor: colors.green,
          backgroundImage: target.avatarUrl == null
              ? null
              : NetworkImage(target.avatarUrl!),
          child: target.avatarUrl == null
              ? Text(
                  target.initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: Text(
            target.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isPending)
          SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.green,
            ),
          )
        else
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: 'absent',
                icon: Icon(Icons.close_rounded, size: 17),
                tooltip: 'Niet aanwezig',
              ),
              ButtonSegment(
                value: 'unknown',
                icon: Icon(Icons.remove_rounded, size: 17),
                tooltip: 'Onbekend',
              ),
              ButtonSegment(
                value: 'present',
                icon: Icon(Icons.check_rounded, size: 17),
                tooltip: 'Aanwezig',
              ),
            ],
            selected: {selectedStatus ?? 'unknown'},
            onSelectionChanged: (selection) {
              switch (selection.first) {
                case 'present':
                  onPresent();
                case 'absent':
                  onAbsent();
                default:
                  onUnknown();
              }
            },
          ),
      ],
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({
    required this.activity,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final HomeActivity activity;
  final bool isSubmitting;
  final Future<void> Function({
    required _FeedbackTarget target,
    required int rating,
    required String comment,
  })
  onSubmit;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  String? _selectedTargetId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<_FeedbackTarget> get _targets {
    if (widget.activity.isOwnedByCurrentUser) {
      return widget.activity.participants
          .where((participant) => participant.id.isNotEmpty)
          .map(
            (participant) => _FeedbackTarget(
              id: participant.id,
              name: participant.displayName,
              initials: participant.initials,
              avatarUrl: participant.avatarUrl,
              attendanceStatus: participant.attendanceStatus,
              feedbackSubmitted: participant.feedbackSubmitted,
            ),
          )
          .toList();
    }

    if (!widget.activity.isJoined || widget.activity.hostId.isEmpty) {
      return const [];
    }

    return [
      _FeedbackTarget(
        id: widget.activity.hostId,
        name: widget.activity.hostFullName,
        initials: _initialsFor(widget.activity.hostFullName),
        avatarUrl: widget.activity.hostAvatarUrl,
        feedbackSubmitted: widget.activity.hostFeedbackSubmitted,
      ),
    ];
  }

  _FeedbackTarget? get _selectedTarget {
    final targets = _targets;
    if (targets.isEmpty) {
      return null;
    }
    return targets.firstWhere(
      (target) => target.id == _selectedTargetId,
      orElse: () => targets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final targets = _targets;
    final selectedTarget = _selectedTarget;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .7),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            if (targets.isEmpty)
              Text(
                widget.activity.isOwnedByCurrentUser
                    ? 'Er zijn nog geen deelnemers om feedback te geven.'
                    : 'Je kunt feedback geven na deelname aan deze activiteit.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final target in targets)
                    ChoiceChip(
                      selected:
                          target.id == (selectedTarget?.id ?? targets.first.id),
                      onSelected: (_) {
                        setState(() {
                          _selectedTargetId = target.id;
                        });
                      },
                      avatar: CircleAvatar(
                        backgroundColor: colors.green100,
                        foregroundColor: colors.green,
                        backgroundImage: target.avatarUrl == null
                            ? null
                            : NetworkImage(target.avatarUrl!),
                        child: target.avatarUrl == null
                            ? Text(
                                target.initials,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      label: Text(target.name),
                    ),
                ],
              ),
              if (selectedTarget?.feedbackSubmitted == true) ...[
                const SizedBox(height: TochSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Feedback opgeslagen. Je kunt deze nog bijwerken.',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.green,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: TochSpacing.sm),
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = star;
                        });
                      },
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TochSpacing.xs),
              TextField(
                controller: _commentController,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Korte feedback',
                  filled: true,
                  fillColor: colors.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TochRadius.md),
                    borderSide: BorderSide(color: colors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TochRadius.md),
                    borderSide: BorderSide(color: colors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TochRadius.md),
                    borderSide: BorderSide(color: colors.green, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: TochSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isSubmitting || selectedTarget == null
                      ? null
                      : () => widget.onSubmit(
                          target: selectedTarget,
                          rating: _rating,
                          comment: _commentController.text.trim(),
                        ),
                  icon: widget.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rate_review_rounded),
                  label: const Text('Feedback opslaan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MissingActivityDetailPage extends StatelessWidget {
  const MissingActivityDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, color: colors.orange, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Activiteit niet gevonden',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(
                  'Open deze activiteit opnieuw vanuit de feed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Terug naar overzicht'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Over deze activiteit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .7),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.ink,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.canReport, required this.onReportPressed});

  final bool canReport;
  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green100,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.green200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: colors.green, size: 22),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Text(
                'Spreek bij voorkeur af op een openbare plek. Deel je afspraak met iemand die je kent.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.green,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
            if (canReport) ...[
              const SizedBox(width: TochSpacing.xs),
              IconButton(
                onPressed: onReportPressed,
                tooltip: 'Rapporteer activiteit',
                icon: Icon(Icons.flag_rounded, color: colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<SafetyReportDraft?> _askForSafetyDetails(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  return showSafetyReportDialog(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
  );
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

HomeActivity _activityWithAttendance(
  HomeActivity activity,
  String profileId,
  String status,
) {
  return activity.copyWith(
    participants: activity.participants
        .map(
          (participant) => participant.id == profileId
              ? participant.copyWith(
                  attendanceStatus: status,
                  attendanceMarkedAt: DateTime.now().toUtc(),
                )
              : participant,
        )
        .toList(),
  );
}

HomeActivity _activityWithSubmittedFeedback(
  HomeActivity activity,
  String targetProfileId,
) {
  if (targetProfileId == activity.hostId) {
    return activity.copyWith(hostFeedbackSubmitted: true);
  }

  return activity.copyWith(
    participants: activity.participants
        .map(
          (participant) => participant.id == targetProfileId
              ? participant.copyWith(feedbackSubmitted: true)
              : participant,
        )
        .toList(),
  );
}
