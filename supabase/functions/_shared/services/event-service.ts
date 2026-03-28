import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreateEventInput = {
  title: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  createdBy?: string;
};

export class EventService {
  constructor(private readonly client: SupabaseClient) {}

  async listEvents() {
    const { data, error } = await this.client
      .from("events")
      .select("id, title, description, required_aura, link, type, created_at")
      .order("required_aura", { ascending: true })
      .order("created_at", { ascending: false });

    if (error) throw error;
    return data;
  }

  async listEligibleEvents() {
    const { data, error } = await this.client.rpc("list_events_with_eligibility");
    if (error) throw error;
    return data;
  }

  async createEvent(input: CreateEventInput) {
    if (!input.title.trim()) {
      throw new Error("Event title is required");
    }

    const normalizedType = input.type === "hackathon" ? "hackathon" : "event";
    const requiredAura = Math.max(0, Number(input.requiredAura ?? 0));

    const { data, error } = await this.client
      .from("events")
      .insert({
        title: input.title.trim(),
        description: input.description?.trim() ?? "",
        required_aura: requiredAura,
        link: input.link?.trim() ?? "",
        type: normalizedType,
        created_by: input.createdBy ?? null,
      })
      .select("id, title, description, required_aura, link, type, created_at")
      .single();

    if (error) throw error;
    return data;
  }
}
