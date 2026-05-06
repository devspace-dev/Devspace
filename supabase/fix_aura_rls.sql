-- Fix RLS for aura_ledger to allow all authenticated users to see entries (for leaderboard)
DROP POLICY IF EXISTS aura_ledger_select_owner ON public.aura_ledger;

CREATE POLICY aura_ledger_select_all
  ON public.aura_ledger
  FOR SELECT
  TO authenticated
  USING (true);

-- Ensure users can see other users' aura (usually already true but being explicit)
DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
CREATE POLICY "Users can view all profiles"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);
