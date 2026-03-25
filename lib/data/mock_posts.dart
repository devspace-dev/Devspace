import '../models/post_model.dart';

final List<PostModel> kMockPosts = [
  PostModel(
    id: '607f1f77bcf86cd7994390a1',
    userId: '507f1f77bcf86cd799439013', // Priya
    content:
        'Just hit 94% accuracy on our facial recognition model 🎯\n\nUsed MobileNetV2 with custom training data from our college. Running live on a Raspberry Pi. Next up: integrating with the attendance portal.\n\nMonth 3 of this project. Worth every late night 🌙',
    tags: ['ML', 'Python', 'OpenCV'],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likes: 48,
    comments: 12,
    reposts: 6,
  ),
  PostModel(
    id: '607f1f77bcf86cd7994390a2',
    userId: '507f1f77bcf86cd799439012', // Aryan
    content:
        'Built a drag-and-drop timetable scheduler ✨\n\nAuto-resolves conflicts using a greedy algorithm + syncs with Google Calendar. Open sourcing it this weekend.\n\nStarted as a hackathon project, now 200+ students want it 😅',
    tags: ['React', 'Algorithms', 'OpenSource'],
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likes: 73,
    comments: 19,
    reposts: 14,
    isLiked: true,
  ),
  PostModel(
    id: '607f1f77bcf86cd7994390a3',
    userId: '507f1f77bcf86cd799439015', // Sneha (Wait Sneha was 4th in list, let's check)
    content:
        'v1.0 of our college design system is live 🎨\n\n40+ components. Dark mode. Full accessibility compliance. Every student project can look polished from day 1.\n\nFigma file + Vue component library — link in bio!',
    tags: ['DesignSystem', 'Vue', 'Figma'],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likes: 91,
    comments: 27,
    reposts: 21,
    isBookmarked: true,
  ),
  PostModel(
    id: '607f1f77bcf86cd7994390a4',
    userId: '507f1f77bcf86cd799439016', // Dev
    content:
        'Rewrote our college API gateway in Go\n\nWent from 800ms avg response time → 43ms 🔥\n\nDockerized, Redis-cached, and fully documented. Performance matters.',
    tags: ['Go', 'Backend', 'Docker'],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likes: 112,
    comments: 34,
    reposts: 29,
  ),
  PostModel(
    id: '607f1f77bcf86cd7994390a5',
    userId: '507f1f77bcf86cd799439014', // Rohan
    content:
        'First prototype of the campus food app is live! 🍱\n\nBrowse menus from all 3 canteens + place orders. Real-time tracking in v0.2.\n\nTesting with 20 beta users. DM me if you want early access 👀',
    tags: ['Flutter', 'Firebase', 'Mobile'],
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likes: 34,
    comments: 8,
    reposts: 4,
  ),
];
