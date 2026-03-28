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

  async getFounderAccess(deviceId: string | null) {
    const { data: authData, error: authError } = await this.client.auth.getUser();
    if (authError || !authData.user) {
      throw new Error("Unauthorized");
    }

    const { data: userRow, error: userError } = await this.client
      .from("users")
      .select("is_admin")
      .eq("id", authData.user.id)
      .single();

    if (userError) throw userError;

    if (userRow?.is_admin !== true || !deviceId) {
      return { authorized: false };
    }

    const { data: deviceRow, error: deviceError } = await this.client
      .from("founder_devices")
      .select("device_id, is_active")
      .eq("user_id", authData.user.id)
      .eq("device_id", deviceId)
      .maybeSingle();

    if (deviceError) throw deviceError;

    return { authorized: deviceRow?.is_active === true };
  }
}
