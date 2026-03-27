# Supabase Setup for DevSpace

1.  **Create Project**: Go to [Supabase](https://supabase.com) and create a new project.
2.  **SQL Editor**: Run [`supabase/devspace_schema.sql`](/Users/mohammad/Desktop/devspace/supabase/devspace_schema.sql) in the Supabase SQL Editor.
    *   This now creates the core social tables plus Q&A tables (`questions`, `question_replies`, `question_votes`) and the solved-answer RPC.
3.  **Authentication**:
    *   Enable Email provider in Authentication -> Providers.
    *   For fast testing on mobile, disable `Confirm email`.
    *   If you keep email confirmation enabled, also fix Authentication -> URL Configuration:
        *   remove any stale `localhost:3000` site URL
        *   set `Site URL` to a real web URL you control, or a temporary placeholder that is not localhost
        *   add proper redirect URLs/deep links later when you intentionally support email auth redirects in the app
4.  **Storage**:
    *   Create a new bucket named `images`.
    *   Set it to "Public".
    *   Add RLS policies to allow authenticated users to upload/delete their own files.
5.  **Environment Variables**:
    *   Get your `Project URL` and `anon public` key from Settings -> API.
    *   Pass them using `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...`.
    *   The app no longer ships with checked-in Supabase fallback credentials.
6.  **If sign-in fails with missing columns**:
    *   Your `users` table is incomplete.
    *   Run [`supabase/devspace_schema.sql`](/Users/mohammad/Desktop/devspace/supabase/devspace_schema.sql) again. It is written to be safe for existing tables.

7.  **Run command example**:
```bash
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL=your-project-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

8.  **Important schema note**:
    *   Re-run [`supabase/devspace_schema.sql`](/Users/mohammad/Desktop/devspace/supabase/devspace_schema.sql) whenever new backend features land.
    *   The current file includes required Q&A count triggers and the solved-answer function. Do not skip this step on older projects.

## Example SQL for Triggers:

```sql
-- Auto-create user profile on signup
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, name, email)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```
