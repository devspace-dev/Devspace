import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export class UserService {
  constructor(private readonly client: SupabaseClient) {}

  async getCurrentUserProfile() {
    const { data: authData, error: authError } = await this.client.auth.getUser();
    if (authError || !authData.user) {
      throw new Error("Unauthorized");
    }

    const { data, error } = await this.client
      .from("users")
      .select(
        "id, name, email, handle, aura_points, aura, current_streak, longest_streak, stack, college, role, branch, year",
      )
      .eq("id", authData.user.id)
      .single();

    if (error) throw error;
    return data;
  }
}
