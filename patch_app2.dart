import 'dart:io';

void main() {
  final file = File('lib/app.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "import 'services/app_review_service.dart';",
    "import 'services/app_review_service.dart';\nimport 'services/supabase_service.dart';"
  );
  
  content = content.replaceFirst(
    "final sender = await context.read<UsersProvider>().getUserById(senderId);",
    "final sender = context.read<UsersProvider>().getUserById(senderId);"
  );

  file.writeAsStringSync(content);
}
