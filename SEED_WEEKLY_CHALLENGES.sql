-- UPDATED SEED DATA FOR WEEKLY CHALLENGES (10+ Questions per Stack)
-- Run this in the Supabase SQL Editor

TRUNCATE public.challenges;

INSERT INTO public.challenges (title, description, difficulty, tech_stack, points_reward, publish_date, is_active)
VALUES 
-- Flutter Stack
('Flutter Rendering Pipeline', 'Explain how the BuildContext works during the layout phase and how to optimize large lists.', 'medium', 'Flutter', 50, CURRENT_DATE, true),
('State Management Logic', 'Compare BLoC vs Provider for a real-time chat application with 1000+ messages per second.', 'hard', 'Flutter', 70, CURRENT_DATE, true),
('Custom Paint Architecture', 'Design a custom circular slider using CustomPainter that handles gesture detection precisely.', 'medium', 'Flutter', 55, CURRENT_DATE, true),
('Dart Memory Management', 'Identify a memory leak in a Flutter app using DevTools and explain how to fix it.', 'hard', 'Flutter', 80, CURRENT_DATE, true),
('App Startup Optimization', 'Analyze the impact of deferred loading on the initial bundle size of a Flutter web app.', 'medium', 'Flutter', 60, CURRENT_DATE, true),
('Animation Physics', 'Create a spring-based physics animation using the AnimationController and Simulation class.', 'medium', 'Flutter', 50, CURRENT_DATE, true),
('Platform Channels', 'Design a secure way to pass sensitive biometric data from Android/iOS to Dart layer.', 'hard', 'Flutter', 90, CURRENT_DATE, true),
('Widget Composition', 'Refactor a deeply nested widget tree into a clean, reusable component-based architecture.', 'easy', 'Flutter', 30, CURRENT_DATE, true),
('Testing Strategy', 'Write a Golden Test for a responsive dashboard that must look identical across 5 screen sizes.', 'medium', 'Flutter', 65, CURRENT_DATE, true),
('CI/CD for Flutter', 'Configure a GitHub Action that automatically signs and uploads an AAB to Play Store.', 'hard', 'Flutter', 100, CURRENT_DATE, true),

-- Node.js Stack
('Event Loop Deep Dive', 'Explain how the libuv thread pool handles asynchronous I/O operations in Node.js.', 'hard', 'Node.js', 75, CURRENT_DATE, true),
('Scalable Microservices', 'Design a communication protocol between 10 microservices using RabbitMQ and Protobuf.', 'hard', 'Node.js', 85, CURRENT_DATE, true),
('Memory Profiling', 'Use the node-inspect tool to find a memory leak in a long-running Express server.', 'medium', 'Node.js', 60, CURRENT_DATE, true),
('Streams and Pipes', 'Process a 10GB log file using Node.js streams without exceeding 100MB of RAM usage.', 'medium', 'Node.js', 55, CURRENT_DATE, true),
('Security Best Practices', 'Implement a JWT-based authentication system with refresh tokens and IP-based rate limiting.', 'medium', 'Node.js', 65, CURRENT_DATE, true),
('Database ACID', 'Explain how to maintain atomicity across multiple MongoDB collections without native transactions.', 'hard', 'Node.js', 80, CURRENT_DATE, true),
('GraphQL Schema Design', 'Build a federated GraphQL gateway that aggregates data from 3 different REST APIs.', 'medium', 'Node.js', 70, CURRENT_DATE, true),
('Worker Threads', 'Offload a CPU-intensive image processing task from the main event loop to a worker thread.', 'hard', 'Node.js', 90, CURRENT_DATE, true),
('TypeScript Integration', 'Migrate a legacy ES5 Node project to TypeScript with strict type checking and no-any rules.', 'easy', 'Node.js', 40, CURRENT_DATE, true),
('Deployment Scaling', 'Configure a Kubernetes HPA (Horizontal Pod Autoscaler) based on custom Prometheus metrics.', 'hard', 'Node.js', 110, CURRENT_DATE, true),

-- Python Stack
('Pandas Performance', 'Vectorize a Python loop that processes 1 million rows in a DataFrame to be 100x faster.', 'medium', 'Python', 55, CURRENT_DATE, true),
('Asyncio Patterns', 'Refactor a synchronous scraping script to use asyncio.gather for parallel requests.', 'medium', 'Python', 60, CURRENT_DATE, true),
('GIL and Multiprocessing', 'Bypass the Global Interpreter Lock (GIL) for a mathematical computation using multiprocessing.', 'hard', 'Python', 85, CURRENT_DATE, true),
('Django ORM Optimization', 'Identify and fix N+1 query problems in a deeply nested Django REST Framework serializer.', 'medium', 'Python', 65, CURRENT_DATE, true),
('FastAPI Architecture', 'Design a dependency injection system for a FastAPI project that handles multiple databases.', 'hard', 'Python', 75, CURRENT_DATE, true),
('Machine Learning Ops', 'Deploy a PyTorch model as a serverless function with cold-start optimization.', 'hard', 'Python', 100, CURRENT_DATE, true),
('Metaprogramming', 'Create a Python decorator that logs the execution time and arguments of any function.', 'easy', 'Python', 30, CURRENT_DATE, true),
('Data Validation', 'Implement a complex Pydantic model with custom validators for a multi-tenant SaaS API.', 'medium', 'Python', 50, CURRENT_DATE, true),
('WebSockets with Starlette', 'Build a real-time notification system using Python WebSockets and Redis Pub/Sub.', 'hard', 'Python', 90, CURRENT_DATE, true),
('Poetry Dependency Management', 'Resolve a complex dependency conflict in a Python project using Poetry lock files.', 'easy', 'Python', 35, CURRENT_DATE, true);
