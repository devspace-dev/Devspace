/// Centralized copy strings for all tour bubbles, modals, and tooltips.
/// Strict rule: Every bubble text must be <= 140 characters.
class TourCopy {
  TourCopy._();

  // S1: Welcome Modal (New User)
  static const String s1WelcomeTitle = 'Welcome to DevSpace';
  static const String s1WelcomeBody =
      'Solve. Post. Compete. Let us earn your first Aura in 2 minutes.';
  static const String s1WelcomePrimary = 'Let us go';
  static const String s1WelcomeCta = s1WelcomePrimary;
  static const String s1WelcomeSkip = 'Skip for now';

  // S1: Existing User Upgrade Modal
  static const String s1UpgradeTitle = 'Glitch got an upgrade';
  static const String s1UpgradeBody =
      'A new look and new Aura rules. Quick tour?';
  static const String s1UpgradePrimary = 'Show me';
  static const String s1UpgradeSkip = 'Not now';

  // S2: Goal / Path Setup Sheet
  static const String s2GoalTitle = 'What do you want to build?';
  static const String s2GoalBody = 'I will set up your Path.';
  static const String s2GoalAction = 'Set up my Path';
  static const String s2GoalLocked = 'Goal locked! 🎯';
  static const String s2GoalLockedBody =
      'Your roadmap is set. Let\'s earn your first Aura.';

  static const String s2OptionDsaTitle = 'Land a placement';
  static const String s2OptionDsaDesc = 'DSA, projects and interview prep';
  static const String s2OptionDsaRoadmapId = 'dsa';

  static const String s2OptionFlutterTitle = 'Build mobile apps';
  static const String s2OptionFlutterDesc = 'Flutter, step by step';
  static const String s2OptionFlutterRoadmapId = 'flutter';

  static const String s2OptionHackathonTitle = 'Win hackathons';
  static const String s2OptionHackathonDesc = 'Team up and ship fast';
  static const String s2OptionHackathonRoadmapId = 'web';

  static const String s2OptionWebTitle = 'Build for the web';
  static const String s2OptionWebDesc = 'HTML, CSS, JS and React';
  static const String s2OptionWebRoadmapId = 'web';

  // S3: Play Tab (New User)
  static const String s3PlayTitle = 'START HERE';
  static const String s3PlayBody =
      'Tap Easy. One correct answer is +5 Aura. That is your first.';

  // S3b: Play Tab (Existing User)
  static const String s3bPlayTitle = 'NEW ARENA RULES';
  static const String s3bPlayBody =
      'Practice: +5 to +20 Aura per question. Daily Mission: +20 or +5. Combat: +5 per correct answer for the winner.';

  // S4: Community Tab
  static const String s4CommunityTitle = 'COMMUNITY FEED';
  static const String s4CommunityBody =
      'Stuck, proud or curious? Tap + and post it. Builders reply fast.';

  // S5: Events Tab
  static const String s5EventsTitle = 'STUDENT OPPORTUNITIES';
  static const String s5EventsBody =
      'Events lists hackathons and internships for B.Tech students. Register directly on organiser pages.';

  // S6: Ranks Tab
  static const String s6RanksTitle = 'LEADERBOARD';
  static const String s6RanksBodyNew =
      'This is the board. Earn 1 Aura and your name joins it.';
  static const String s6RanksBodyClimb =
      'Climb the board with Practice, Daily Missions and Combat.';

  // S7: First Practice Reward Modal
  static const String s7RewardTitle = 'FIRST ONE DONE!';
  static const String s7RewardBody =
      'First one done. You are on the board now.';
  static const String s7BadgeEarned = 'Badge earned: First Practice Solve';
  static const String s7KeepGoing = 'Keep going';
  static const String s7SeeRank = 'See my rank';

  // S8: Quests
  static const String s8CardTitle = 'FIRST QUESTS';
  static const String s8QuestPath = 'Pick your path';
  static const String s8QuestSolve = 'Solve your first question';
  static const String s8QuestPost = 'Make your first post';
  static const String s8QuestEvent = 'Find an event';
  static const String s8QuestBadge = 'Earn your first badge';
}
