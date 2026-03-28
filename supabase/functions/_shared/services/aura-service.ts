import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export class AuraService {
  constructor(private readonly client: SupabaseClient) {}

  async getSummary(userId?: string) {
    const { data, error } = await this.client.rpc("get_user_aura_summary", {
      p_user_id: userId ?? null,
    });

    if (error) throw error;
    return data;
  }

  async refreshStreak() {
    const { data, error } = await this.client.rpc("refresh_user_streak_if_needed");
    if (error) throw error;
    return data;
  }
}
