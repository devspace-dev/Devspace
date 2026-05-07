import 'package:devspace/models/aura_summary_model.dart';
import 'package:devspace/models/daily_challenge_model.dart';
import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchOverview loads aura, events, challenge, and refreshes user', () async {
    var refreshCalls = 0;
    final provider = EngagementProvider(
      auraSummaryLoader: () async => _summary(),
      eligibleEventsLoader: () async => [_event(unlocked: true)],
      dailyChallengeLoader: ({techStack}) async => _challenge(),
      refreshCurrentUser: () async {
        refreshCalls += 1;
      },
    );

    await provider.fetchOverview();

    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
    expect(provider.auraSummary?.auraPoints, 120);
    expect(provider.events, hasLength(1));
    expect(provider.dailyChallenge?.title, 'Ship a profile polish');
    expect(refreshCalls, 1);
  });

  test('submitDailyChallenge rejects empty submissions before calling backend', () async {
    var submitCalls = 0;
    final provider = EngagementProvider(
      dailyChallengeSubmitter: ({
        required submissionText,
        required submissionLink,
      }) async {
        submitCalls += 1;
        return {};
      },
    );

    final success = await provider.submitDailyChallenge(
      submissionText: '   ',
      submissionLink: '',
    );

    expect(success, isFalse);
    expect(submitCalls, 0);
    expect(
      provider.error,
      'Add your solution text or a link before submitting.',
    );
  });

  test('submitDailyChallenge refreshes overview after a successful submission', () async {
    var submitCalls = 0;
    var refreshCalls = 0;
    var challengeLoads = 0;
    final provider = EngagementProvider(
      auraSummaryLoader: () async => _summary(),
      eligibleEventsLoader: () async => [_event(unlocked: true)],
      dailyChallengeLoader: ({techStack}) async {
        challengeLoads += 1;
        return _challenge(completed: challengeLoads > 0);
      },
      dailyChallengeSubmitter: ({
        required submissionText,
        required submissionLink,
      }) async {
        submitCalls += 1;
        expect(submissionText, 'Built the solution');
        expect(submissionLink, 'https://example.com/demo');
        return {'ok': true};
      },
      refreshCurrentUser: () async {
        refreshCalls += 1;
      },
    );

    final success = await provider.submitDailyChallenge(
      submissionText: 'Built the solution',
      submissionLink: 'https://example.com/demo',
    );

    expect(success, isTrue);
    expect(submitCalls, 1);
    expect(refreshCalls, 1);
    expect(provider.error, isNull);
    expect(provider.dailyChallenge?.completed, isTrue);
  });
}

AuraSummaryModel _summary() {
  return const AuraSummaryModel(
    userId: 'user-1',
    auraPoints: 120,
    level: 'Builder',
    currentStreak: 3,
    longestStreak: 5,
    lastChallengeCompletedOn: null,
    badges: [],
  );
}

DailyChallengeModel _challenge({bool completed = false}) {
  return DailyChallengeModel(
    assignmentId: 'assignment-1',
    challengeId: 'challenge-1',
    assignedDate: DateTime.utc(2026, 3, 28),
    selectedTechStack: 'Flutter',
    completed: completed,
    completedAt: completed ? DateTime.utc(2026, 3, 28, 9) : null,
    title: 'Ship a profile polish',
    description: 'Improve one profile detail screen and explain the change.',
    difficulty: 'easy',
    techStack: 'Flutter',
    pointsReward: 20,
    missionType: 'coding',
    question: 'Improve one profile detail screen and explain the change.',
    options: const [],
    link: 'https://example.com/challenge',
    isCorrect: false,
  );
}

EventAccessModel _event({required bool unlocked}) {
  return EventAccessModel(
    id: 'event-1',
    title: 'Hack Night',
    description: 'Campus build sprint.',
    requiredAura: 80,
    link: 'https://example.com/event',
    type: 'event',
    unlocked: unlocked,
    locked: !unlocked,
  );
}
