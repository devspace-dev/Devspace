class VerifiedResource {
  final String title;
  final String type; // 'Official Docs', 'Reference', 'Textbook', 'Guide'
  final String? url;

  const VerifiedResource({
    required this.title,
    required this.type,
    this.url,
  });
}

class RoadmapNode {
  final String id;
  final String title;
  final String description;
  final String whyItMatters;
  final List<String> prerequisites;
  final String estimatedHours;
  final List<String> subTopics;
  final String practiceProjectIdea;
  final List<VerifiedResource> resources;
  final List<String> nextNodeIds;

  const RoadmapNode({
    required this.id,
    required this.title,
    required this.description,
    required this.whyItMatters,
    this.prerequisites = const [],
    required this.estimatedHours,
    required this.subTopics,
    required this.practiceProjectIdea,
    this.resources = const [],
    this.nextNodeIds = const [],
  });
}

class RoadmapTrack {
  final String id;
  final String title;
  final String subtitle;
  final String stackLabel;
  final List<RoadmapNode> nodes;

  const RoadmapTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.stackLabel,
    required this.nodes,
  });
}

const List<RoadmapTrack> kRoadmapTracks = [
  // ===========================================================================
  // 1. FLUTTER & DART
  // ===========================================================================
  RoadmapTrack(
    id: 'flutter',
    title: 'Flutter & Dart',
    subtitle: 'Cross-platform mobile apps for Android & iOS',
    stackLabel: 'Mobile',
    nodes: [
      RoadmapNode(
        id: 'fl_dart_basics',
        title: 'Dart & Type System',
        description:
            'Understand Dart sound null safety, records, patterns, object-oriented concepts, and concurrency with isolates.',
        whyItMatters:
            'Dart powers every line of your Flutter app. Writing type-safe, idiomatic Dart prevents runtime crashes and makes complex UI code readable.',
        prerequisites: [],
        estimatedHours: '8-10 hours',
        subTopics: [
          'Sound Null Safety (nullable vs non-nullable)',
          'Dart 3 Pattern Matching & Records',
          'Classes, Mixins & Extension methods',
          'Generics & Collections (Lists, Sets, Maps)',
          'Futures, async/await & Streams',
        ],
        practiceProjectIdea:
            'Write a command-line expense tracker that parses JSON inputs and uses sealed classes to model different transaction types.',
        resources: [
          VerifiedResource(
            title: 'Dart Language Tour (Official Docs)',
            type: 'Official Docs',
            url: 'https://dart.dev/guides/language/language-tour',
          ),
        ],
        nextNodeIds: ['fl_widget_tree'],
      ),
      RoadmapNode(
        id: 'fl_widget_tree',
        title: 'Widget Tree & Layouts',
        description:
            'Master composition with Stateless and Stateful widgets, constraints, Flex layouts, and responsive design.',
        whyItMatters:
            'In Flutter, "everything is a widget". Mastering box constraints eliminates the dreaded RenderFlex overflow.',
        prerequisites: ['fl_dart_basics'],
        estimatedHours: '10-12 hours',
        subTopics: [
          'BoxConstraints (Constraints go down, sizes go up)',
          'Rows, Columns, Flex, and Expanded/Flexible',
          'Stack, Positioned, and Align',
          'Custom scroll views with Slivers',
          'MediaQuery and LayoutBuilder responsiveness',
        ],
        practiceProjectIdea:
            'Build a responsive student profile page that adapts seamlessly between portrait mobile screens and wide landscape tablets.',
        resources: [
          VerifiedResource(
            title: 'Flutter Layout Concepts (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/ui/layout',
          ),
        ],
        nextNodeIds: ['fl_state_mgmt'],
      ),
      RoadmapNode(
        id: 'fl_state_mgmt',
        title: 'State Management (Provider)',
        description:
            'Learn unidirectional data flow, ChangeNotifier, InheritedWidget, and scoped state injection.',
        whyItMatters:
            'Separating business logic from UI rendering allows multiple screens to share synchronized state without spaghetti callbacks.',
        prerequisites: ['fl_widget_tree'],
        estimatedHours: '12-14 hours',
        subTopics: [
          'Ephemeral (local) vs App-level state',
          'ChangeNotifier and notifyListeners()',
          'ChangeNotifierProvider and MultiProvider',
          'context.watch vs context.read performance rules',
          'Selector pattern for granular rebuild prevention',
        ],
        practiceProjectIdea:
            'Create an in-memory shopping cart with item quantity steppers, cart badge count, and total aura calculation.',
        resources: [
          VerifiedResource(
            title: 'Simple App State Management (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/data-and-backend/state-mgmt/simple',
          ),
        ],
        nextNodeIds: ['fl_async_networking'],
      ),
      RoadmapNode(
        id: 'fl_async_networking',
        title: 'REST APIs & Offline Storage',
        description:
            'Connect your app to real backends using HTTP client libraries, error handling, and local SharedPreferences / SQLite.',
        whyItMatters:
            'Real-world college apps must function on spotty campus Wi-Fi with graceful offline caching and loading indicators.',
        prerequisites: ['fl_state_mgmt'],
        estimatedHours: '10-12 hours',
        subTopics: [
          'HTTP methods (GET, POST, PATCH, DELETE)',
          'JSON serialization with type-safe model factories',
          'SharedPreferences key-value caching',
          'Connection retry, timeouts and exponential backoff',
          'Handling authentication bearer tokens securely',
        ],
        practiceProjectIdea:
            'Build a campus noticeboard app that fetches notices from a REST endpoint and caches the latest 20 items offline.',
        resources: [
          VerifiedResource(
            title: 'Fetch Data Over the Internet (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/cookbook/networking/fetch-data',
          ),
          VerifiedResource(
            title: 'Store Key-Value Data (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/cookbook/persistence/key-value',
          ),
        ],
        nextNodeIds: ['fl_architecture_testing'],
      ),
      RoadmapNode(
        id: 'fl_architecture_testing',
        title: 'Architecture & Testing',
        description:
            'Structure production apps using Clean Architecture (Data, Domain, Presentation) and write unit & widget tests.',
        whyItMatters:
            'Writing automated tests guarantees that new feature releases do not break authentication or critical community flows.',
        prerequisites: ['fl_async_networking'],
        estimatedHours: '10-14 hours',
        subTopics: [
          'Layered architecture: Presentation, Logic, Data',
          'Unit testing functions and providers with package:test',
          'Widget testing with WidgetTester and pumpAndSettle',
          'Mocking external network APIs and storage',
          'Static code analysis with flutter analyze & strict lints',
        ],
        practiceProjectIdea:
            'Write a full test suite verifying that a login form validates college emails and displays error banners for weak passwords.',
        resources: [
          VerifiedResource(
            title: 'Testing Flutter Apps (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/testing/overview',
          ),
        ],
        nextNodeIds: ['fl_release_ci'],
      ),
      RoadmapNode(
        id: 'fl_release_ci',
        title: 'Android/iOS Release & CI',
        description:
            'Configure Gradle, ProGuard / R8 rules, app icons, splash screens, and compile signed Android App Bundles.',
        whyItMatters:
            'Ship your app to real college users on Google Play Store without build failures, asset stripping, or JVM version mismatches.',
        prerequisites: ['fl_architecture_testing'],
        estimatedHours: '8-10 hours',
        subTopics: [
          'Keystore generation and key.properties signing',
          'ProGuard and R8 minify & obfuscation rules',
          'Gradle build script configuration (compileSdk, ndkVersion)',
          'App icons and native launch screen assets',
          'Google Play Console internal testing track deployment',
        ],
        practiceProjectIdea:
            'Generate a signed release App Bundle (.aab) with ProGuard enabled, verify APK installation on a physical Android phone.',
        resources: [
          VerifiedResource(
            title: 'Build and Release an Android App (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.flutter.dev/deployment/android',
          ),
        ],
        nextNodeIds: [],
      ),
    ],
  ),

  // ===========================================================================
  // 2. WEB FRONTEND
  // ===========================================================================
  RoadmapTrack(
    id: 'frontend',
    title: 'Web Frontend',
    subtitle: 'Modern web applications with React, TypeScript & Next.js',
    stackLabel: 'Frontend',
    nodes: [
      RoadmapNode(
        id: 'fe_html_css',
        title: 'Semantic HTML5 & Modern CSS',
        description:
            'Master semantic markup, CSS Flexbox, Grid, custom properties (CSS variables), and media queries.',
        whyItMatters:
            'Semantic markup ensures web accessibility, SEO optimization, and clean page structure before adding JavaScript frameworks.',
        prerequisites: [],
        estimatedHours: '8-10 hours',
        subTopics: [
          'Semantic tags (article, nav, section, header, main)',
          'CSS Flexbox axes and alignment',
          'CSS Grid 2D layout systems',
          'Responsive design with fluid typography',
          'CSS variables and dark mode theming',
        ],
        practiceProjectIdea:
            'Create a fully responsive landing page for a college hackathon with light and dark theme toggles.',
        resources: [
          VerifiedResource(
            title: 'MDN Web Development Learn (Official Docs)',
            type: 'Official Docs',
            url: 'https://developer.mozilla.org/en-US/docs/Learn',
          ),
        ],
        nextNodeIds: ['fe_js_ts'],
      ),
      RoadmapNode(
        id: 'fe_js_ts',
        title: 'JavaScript & TypeScript',
        description:
            'Master ES6+, Promises, async/await, closures, prototypes, and TypeScript type declarations & generics.',
        whyItMatters:
            'TypeScript catches 80% of UI bugs at compile time by validating API shapes and state transitions.',
        prerequisites: ['fe_html_css'],
        estimatedHours: '12-14 hours',
        subTopics: [
          'Event loop, Microtasks, and Promises',
          'Array methods: map, filter, reduce, find',
          'TypeScript interfaces, types, and union types',
          'Generics and utility types (Partial, Omit, Pick)',
          'DOM event bubbling and delegation',
        ],
        practiceProjectIdea:
            'Build a type-safe GitHub user search dashboard that queries the public GitHub REST API with debounced search.',
        resources: [
          VerifiedResource(
            title: 'MDN JavaScript Guide (Official Docs)',
            type: 'Official Docs',
            url: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
          ),
          VerifiedResource(
            title: 'TypeScript Handbook (Official Docs)',
            type: 'Official Docs',
            url: 'https://www.typescriptlang.org/docs/handbook/intro.html',
          ),
        ],
        nextNodeIds: ['fe_react_basics'],
      ),
      RoadmapNode(
        id: 'fe_react_basics',
        title: 'React Fundamentals & Hooks',
        description:
            'Build declarative user interfaces using JSX, props, state, useEffect, and component composition.',
        whyItMatters:
            'React is the industry standard for web application interfaces, powering interactive single-page dashboards.',
        prerequisites: ['fe_js_ts'],
        estimatedHours: '14-16 hours',
        subTopics: [
          'JSX and declarative rendering',
          'useState and pure state updater functions',
          'useEffect lifecycle and dependency arrays',
          'Handling form inputs and controlled components',
          'Lifting state up and component hierarchy',
        ],
        practiceProjectIdea:
            'Build a Kanban task board with columns for Backlog, In Progress, and Done with local storage persistence.',
        resources: [
          VerifiedResource(
            title: 'React Learn Guide (Official Docs)',
            type: 'Official Docs',
            url: 'https://react.dev/learn',
          ),
        ],
        nextNodeIds: ['fe_nextjs'],
      ),
      RoadmapNode(
        id: 'fe_nextjs',
        title: 'Next.js & Server Components',
        description:
            'Master Server-Side Rendering (SSR), Static Site Generation (SSG), App Router, and API routes.',
        whyItMatters:
            'Next.js delivers fast initial page loads and excellent SEO by executing data fetches on the server.',
        prerequisites: ['fe_react_basics'],
        estimatedHours: '12-16 hours',
        subTopics: [
          'App Router file conventions (page.tsx, layout.tsx, loading.tsx)',
          'React Server Components (RSC) vs Client Components',
          'Server Actions for database mutations',
          'Static generation (ISR) and dynamic caching',
          'Route handlers and middleware',
        ],
        practiceProjectIdea:
            'Develop a student project showcase blog with server-side rendered markdown posts and dynamic author pages.',
        resources: [
          VerifiedResource(
            title: 'Next.js Documentation (Official Docs)',
            type: 'Official Docs',
            url: 'https://nextjs.org/docs',
          ),
        ],
        nextNodeIds: ['fe_performance'],
      ),
      RoadmapNode(
        id: 'fe_performance',
        title: 'Web Performance & Security',
        description:
            'Optimize Core Web Vitals (LCP, FID, CLS), asset loading, bundle size, and guard against XSS & CSRF.',
        whyItMatters:
            'Slow web apps lose student users within 3 seconds. Optimizing bundles ensures snappy loading even on mobile browsers.',
        prerequisites: ['fe_nextjs'],
        estimatedHours: '8-10 hours',
        subTopics: [
          'Core Web Vitals (Largest Contentful Paint, Cumulative Layout Shift)',
          'Image optimization and lazy loading',
          'Code splitting with dynamic imports',
          'Cross-Site Scripting (XSS) and Content Security Policy (CSP)',
          'Lighthouse auditing and bundle analysis',
        ],
        practiceProjectIdea:
            'Audit a Next.js app using Chrome Lighthouse, reduce bundle size by 40% with dynamic imports, and score 95+ performance.',
        resources: [
          VerifiedResource(
            title: 'Web.dev Fast Performance Guide (Official Docs)',
            type: 'Official Docs',
            url: 'https://web.dev/explore/fast',
          ),
        ],
        nextNodeIds: [],
      ),
    ],
  ),

  // ===========================================================================
  // 3. BACKEND ENGINEERING
  // ===========================================================================
  RoadmapTrack(
    id: 'backend',
    title: 'Backend Engineering',
    subtitle: 'Scalable APIs, relational databases, caching & distributed systems',
    stackLabel: 'Backend',
    nodes: [
      RoadmapNode(
        id: 'be_networking',
        title: 'HTTP, REST & Networking',
        description:
            'Understand TCP/IP, DNS, HTTP/1.1 vs HTTP/2, status codes, headers, and RESTful resource modeling.',
        whyItMatters:
            'Every client application communicates over HTTP. Understanding connection pooling and network latency is essential for fast APIs.',
        prerequisites: [],
        estimatedHours: '6-8 hours',
        subTopics: [
          'TCP handshake and TLS encryption',
          'HTTP methods and idempotent actions (GET, PUT, DELETE)',
          'Status codes (2xx, 3xx, 4xx, 5xx)',
          'CORS, preflight OPTIONS, and security headers',
          'Designing clean RESTful resource endpoints',
        ],
        practiceProjectIdea:
            'Build a raw HTTP REST server from scratch that parses query parameters, handles JSON payloads, and returns correct HTTP status codes.',
        resources: [
          VerifiedResource(
            title: 'MDN HTTP Overview (Official Docs)',
            type: 'Official Docs',
            url: 'https://developer.mozilla.org/en-US/docs/Web/HTTP',
          ),
        ],
        nextNodeIds: ['be_sql_db'],
      ),
      RoadmapNode(
        id: 'be_sql_db',
        title: 'PostgreSQL & Schema Design',
        description:
            'Master relational database modeling, normalization, indexes (B-Tree, GIN), joins, transactions, and ACID properties.',
        whyItMatters:
            'Data integrity is paramount. Bad schemas lead to data corruption, race conditions, and sluggish queries as users scale.',
        prerequisites: ['be_networking'],
        estimatedHours: '12-16 hours',
        subTopics: [
          'Entity-Relationship modeling and Foreign Keys',
          'Transactions with BEGIN, COMMIT, ROLLBACK and isolation levels',
          'B-Tree and composite indexes for fast lookups',
          'Row-Level Security (RLS) policies and security definer functions',
          'Query optimization with EXPLAIN ANALYZE',
        ],
        practiceProjectIdea:
            'Design a normalized database schema for a student leaderboard with transactions that update user points and ledger logs atomically.',
        resources: [
          VerifiedResource(
            title: 'PostgreSQL Official Documentation',
            type: 'Official Docs',
            url: 'https://www.postgresql.org/docs/current/',
          ),
        ],
        nextNodeIds: ['be_auth_security'],
      ),
      RoadmapNode(
        id: 'be_auth_security',
        title: 'Authentication & API Security',
        description:
            'Implement secure authentication with bcrypt/argon2 hashing, JWT access tokens, refresh tokens, and rate limiting.',
        whyItMatters:
            'Leaked student passwords or unauthenticated endpoints expose student data. Security must be built-in, not an afterthought.',
        prerequisites: ['be_sql_db'],
        estimatedHours: '10-12 hours',
        subTopics: [
          'Password hashing with salted bcrypt/argon2',
          'JWT structure, signing keys, and token expiration',
          'HttpOnly SameSite cookies vs Bearer authorization headers',
          'Rate limiting and brute force protection',
          'SQL injection prevention with parameterized queries',
        ],
        practiceProjectIdea:
            'Build a standalone authentication microservice with sign-up, email verification, token refresh rotation, and rate-limited login.',
        resources: [
          VerifiedResource(
            title: 'OWASP Top 10 Web Application Security',
            type: 'Security Reference',
            url: 'https://owasp.org/www-project-top-ten/',
          ),
        ],
        nextNodeIds: ['be_caching_queues'],
      ),
      RoadmapNode(
        id: 'be_caching_queues',
        title: 'Redis Caching & Message Queues',
        description:
            'Speed up read-heavy workloads with Redis in-memory caching, Cache-Aside pattern, and asynchronous message queues.',
        whyItMatters:
            'Databases cannot handle 10,000 simultaneous requests per second for the same leaderboard. In-memory caching provides sub-millisecond responses.',
        prerequisites: ['be_auth_security'],
        estimatedHours: '10-14 hours',
        subTopics: [
          'Redis data structures: Strings, Hashes, Sorted Sets',
          'Cache-Aside pattern and cache invalidation strategies',
          'TTL and LRU eviction policies',
          'Background worker queues for email and notification delivery',
          'Pub/Sub messaging for real-time updates',
        ],
        practiceProjectIdea:
            'Implement a live leaderboard powered by Redis Sorted Sets (ZADD, ZREVRANGE) supporting 10,000 updates per minute.',
        resources: [
          VerifiedResource(
            title: 'Redis Documentation (Official Docs)',
            type: 'Official Docs',
            url: 'https://redis.io/docs/latest/',
          ),
        ],
        nextNodeIds: ['be_docker_system_design'],
      ),
      RoadmapNode(
        id: 'be_docker_system_design',
        title: 'Docker & Scalable System Design',
        description:
            'Containerize microservices with Docker, configure multi-stage builds, load balancers, database sharding, and CDN caching.',
        whyItMatters:
            'Prepares you for technical engineering interviews and empowers you to deploy reliable, scalable cloud infrastructures.',
        prerequisites: ['be_caching_queues'],
        estimatedHours: '14-18 hours',
        subTopics: [
          'Dockerfile creation and multi-stage build optimization',
          'Docker Compose for multi-container local development',
          'Load balancing with Nginx / reverse proxies',
          'Database replication (Read Replicas) vs Sharding',
          'CAP theorem and eventual consistency in distributed systems',
        ],
        practiceProjectIdea:
            'Containerize an API service and PostgreSQL database with Docker Compose, and document a system design diagram for handling 50k DAU.',
        resources: [
          VerifiedResource(
            title: 'Docker Getting Started Guide (Official Docs)',
            type: 'Official Docs',
            url: 'https://docs.docker.com/get-started/',
          ),
          VerifiedResource(
            title: 'Designing Data-Intensive Applications (Book)',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: [],
      ),
    ],
  ),

  // ===========================================================================
  // 4. AI / ML FOUNDATIONS
  // ===========================================================================
  RoadmapTrack(
    id: 'ai_ml',
    title: 'AI / ML Foundations',
    subtitle: 'From linear algebra and PyTorch to LLMs and RAG agents',
    stackLabel: 'AI / ML',
    nodes: [
      RoadmapNode(
        id: 'ai_python_numpy',
        title: 'Python for Data & Vector Math',
        description:
            'Master NumPy vectorization, broadcasting, multidimensional arrays, and Pandas dataframes.',
        whyItMatters:
            'Vectorized operations in NumPy run in compiled C and are up to 100x faster than standard Python loops for machine learning datasets.',
        prerequisites: [],
        estimatedHours: '8-10 hours',
        subTopics: [
          'NumPy ndarray creation, indexing, and slicing',
          'Vector and matrix operations (dot product, matrix multiply)',
          'Broadcasting rules and array shapes',
          'Pandas data loading, filtering, and cleaning',
          'Data visualization with Matplotlib',
        ],
        practiceProjectIdea:
            'Build a data cleaning and exploratory analysis notebook that analyzes real college exam scores and generates correlation heatmaps.',
        resources: [
          VerifiedResource(
            title: 'NumPy Quickstart Guide (Official Docs)',
            type: 'Official Docs',
            url: 'https://numpy.org/doc/stable/user/absolute_beginners.html',
          ),
        ],
        nextNodeIds: ['ai_classical_ml'],
      ),
      RoadmapNode(
        id: 'ai_classical_ml',
        title: 'Classical Machine Learning',
        description:
            'Learn linear regression, logistic regression, decision trees, random forests, feature scaling, and model evaluation metrics.',
        whyItMatters:
            'Classical ML models are interpretable, fast to train on CPUs, and often outperform deep learning on tabular business data.',
        prerequisites: ['ai_python_numpy'],
        estimatedHours: '12-14 hours',
        subTopics: [
          'Supervised vs Unsupervised learning paradigms',
          'Loss functions: MSE, Binary Cross-Entropy',
          'Overfitting vs underfitting, bias-variance tradeoff',
          'Evaluation metrics: Precision, Recall, F1-score, ROC-AUC',
          'Scikit-Learn pipelines and hyperparameter tuning',
        ],
        practiceProjectIdea:
            'Train a student placement prediction model with Scikit-Learn using academic history, hackathons attended, and mock interview scores.',
        resources: [
          VerifiedResource(
            title: 'Scikit-Learn Tutorials (Official Docs)',
            type: 'Official Docs',
            url: 'https://scikit-learn.org/stable/tutorial/index.html',
          ),
        ],
        nextNodeIds: ['ai_deep_learning'],
      ),
      RoadmapNode(
        id: 'ai_deep_learning',
        title: 'Deep Learning & PyTorch',
        description:
            'Understand neural network forward/backward propagation, autograd, activation functions, optimizers, and convolutional networks.',
        whyItMatters:
            'Deep learning enables modern computer vision, speech recognition, and natural language understanding via layered representation learning.',
        prerequisites: ['ai_classical_ml'],
        estimatedHours: '14-18 hours',
        subTopics: [
          'Tensors and CUDA GPU acceleration',
          'Automatic differentiation with torch.autograd',
          'Building nn.Module models and training loops',
          'Optimizers: SGD, AdamW and learning rate schedulers',
          'Convolutional layers (CNNs) for image recognition',
        ],
        practiceProjectIdea:
            'Train a PyTorch neural network to classify handwritten mathematical symbols with 95%+ validation accuracy.',
        resources: [
          VerifiedResource(
            title: 'PyTorch Basics Tutorial (Official Docs)',
            type: 'Official Docs',
            url: 'https://pytorch.org/tutorials/beginner/basics/intro.html',
          ),
        ],
        nextNodeIds: ['ai_transformers_rag'],
      ),
      RoadmapNode(
        id: 'ai_transformers_rag',
        title: 'Transformers, LLMs & RAG',
        description:
            'Understand self-attention mechanisms, pretrained LLMs, prompt engineering, vector embeddings, and Retrieval-Augmented Generation.',
        whyItMatters:
            'Modern AI developer tools rely on generative models and semantic search over private student codebases and documents.',
        prerequisites: ['ai_deep_learning'],
        estimatedHours: '14-18 hours',
        subTopics: [
          'Self-attention and Transformer architecture',
          'Hugging Face Transformers library and model hubs',
          'Text embeddings and cosine similarity search',
          'Vector databases for document chunk indexing',
          'Building a Retrieval-Augmented Generation (RAG) pipeline',
        ],
        practiceProjectIdea:
            'Build a syllabus Q&A bot using Google Gemini API and vector embeddings that answers questions strictly from course PDF slides.',
        resources: [
          VerifiedResource(
            title: 'Hugging Face Transformers (Official Docs)',
            type: 'Official Docs',
            url: 'https://huggingface.co/docs/transformers/index',
          ),
          VerifiedResource(
            title: 'Google Gemini API Documentation',
            type: 'Official Docs',
            url: 'https://ai.google.dev/gemini-api/docs',
          ),
        ],
        nextNodeIds: [],
      ),
    ],
  ),

  // ===========================================================================
  // 5. DATA STRUCTURES & ALGORITHMS (DSA)
  // ===========================================================================
  RoadmapTrack(
    id: 'dsa',
    title: 'Data Structures & Algorithms',
    subtitle: 'Core problem solving, time complexity, and technical interview mastery',
    stackLabel: 'DSA',
    nodes: [
      RoadmapNode(
        id: 'dsa_complexity',
        title: 'Asymptotic Analysis & Big O',
        description:
            'Understand worst-case, average-case, and best-case time complexity, space complexity, and recurrence relations.',
        whyItMatters:
            'Knowing time complexity prevents writing O(n^2) nested loops that freeze apps when dealing with thousands of student records.',
        prerequisites: [],
        estimatedHours: '4-6 hours',
        subTopics: [
          'Big O, Big Omega, and Big Theta definitions',
          'Constant O(1), Logarithmic O(log n), Linear O(n)',
          'Quadratic O(n^2) vs Exponential O(2^n)',
          'Auxiliary space vs total space complexity',
          'Master Theorem for divide-and-conquer recurrences',
        ],
        practiceProjectIdea:
            'Benchmark linear search vs binary search on 1,000,000 integers and plot execution times against increasing dataset sizes.',
        resources: [
          VerifiedResource(
            title: 'Introduction to Algorithms (CLRS)',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: ['dsa_arrays_strings'],
      ),
      RoadmapNode(
        id: 'dsa_arrays_strings',
        title: 'Arrays, Strings & Two Pointers',
        description:
            'Master in-place manipulation, two-pointer convergence, sliding window patterns, and prefix sum arrays.',
        whyItMatters:
            'Array and string problems constitute over 40% of standard coding assessments for software engineering internships.',
        prerequisites: ['dsa_complexity'],
        estimatedHours: '10-12 hours',
        subTopics: [
          'In-place array reversals and rotations',
          'Two pointers: opposite ends and fast/slow runners',
          'Sliding window (fixed vs variable length)',
          'Prefix sums for constant time subarray range queries',
          'Hash map frequency counting patterns',
        ],
        practiceProjectIdea:
            'Implement an optimized algorithm to find the longest substring without repeating characters in O(n) time.',
        resources: [
          VerifiedResource(
            title: 'Algorithm Design Manual by Steven Skiena',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: ['dsa_linked_lists_stacks'],
      ),
      RoadmapNode(
        id: 'dsa_linked_lists_stacks',
        title: 'Linked Lists, Stacks & Queues',
        description:
            'Understand pointer rewiring, cycle detection, monotonic stacks, and FIFO/LIFO execution pipelines.',
        whyItMatters:
            'Stacks and queues model browser history, undo buffers, call stacks, and BFS graph traversals.',
        prerequisites: ['dsa_arrays_strings'],
        estimatedHours: '10-12 hours',
        subTopics: [
          'Singly and Doubly linked list pointer management',
          'Floyd Cycle Finding algorithm (tortoise and hare)',
          'Monotonic stack for Next Greater Element',
          'Min/Max Stack with O(1) retrieval',
          'Circular queue and deque implementation',
        ],
        practiceProjectIdea:
            'Build a syntax validator that checks matching braces in code snippets using a stack with detailed error line indicators.',
        resources: [
          VerifiedResource(
            title: 'Algorithms 4th Edition by Sedgewick',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: ['dsa_trees_graphs'],
      ),
      RoadmapNode(
        id: 'dsa_trees_graphs',
        title: 'Trees & Graph Traversal',
        description:
            'Master Binary Search Trees (BST), Breadth-First Search (BFS), Depth-First Search (DFS), Dijkstra, and Topological Sort.',
        whyItMatters:
            'Graphs model social networks, dependency resolution in package managers, and route optimization in mapping applications.',
        prerequisites: ['dsa_linked_lists_stacks'],
        estimatedHours: '14-18 hours',
        subTopics: [
          'Binary Tree traversals (Inorder, Preorder, Postorder, Level-order)',
          'BST search, insertion, and validation properties',
          'Graph representations (Adjacency List vs Matrix)',
          'Breadth-First Search for shortest unweighted paths',
          'Depth-First Search for cycle detection and topological sorting',
        ],
        practiceProjectIdea:
            'Implement a course prerequisite scheduler that detects impossible circular dependencies using Kahn Topological Sort algorithm.',
        resources: [
          VerifiedResource(
            title: 'Algorithms 4th Edition by Sedgewick',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: ['dsa_dynamic_programming'],
      ),
      RoadmapNode(
        id: 'dsa_dynamic_programming',
        title: 'Recursion & Dynamic Programming',
        description:
            'Master top-down memoization, bottom-up tabulation, state transition invariants, and classical DP problems.',
        whyItMatters:
            'DP solves complex optimization problems by breaking them into overlapping subproblems without recalculation.',
        prerequisites: ['dsa_trees_graphs'],
        estimatedHours: '16-20 hours',
        subTopics: [
          'Recursive backtracking and decision trees',
          'Top-down Memoization vs Bottom-up Tabulation',
          '0/1 Knapsack and subset sum problems',
          'Longest Common Subsequence and Edit Distance',
          'State compression and space optimization',
        ],
        practiceProjectIdea:
            'Implement the dynamic programming Edit Distance (Levenshtein) algorithm to build a typo auto-correction helper.',
        resources: [
          VerifiedResource(
            title: 'Introduction to Algorithms (CLRS)',
            type: 'Textbook Guide',
          ),
        ],
        nextNodeIds: [],
      ),
    ],
  ),
];
