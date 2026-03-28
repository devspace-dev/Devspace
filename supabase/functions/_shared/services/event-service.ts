import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreateEventInput = {
  title: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  createdBy?: string;
};

type UpdateEventInput = {
  title?: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  isActive?: boolean;
};

export class EventService {
  constructor(private readonly client: SupabaseClient) {}

  async listEvents(includeInactive = false) {
    let query = this.client
      .from("events")
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at",
      )
      .order("required_aura", { ascending: true })
      .order("created_at", { ascending: false });

    if (!includeInactive) {
      query = query.eq("is_active", true);
    }

    const { data, error } = await query;

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
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at",
      )
      .single();

    if (error) throw error;
    return data;
  }

  async updateEvent(eventId: string, input: UpdateEventInput) {
    const updatePayload: Record<string, unknown> = {};
    if (input.title != null) updatePayload.title = input.title.trim();
    if (input.description != null) {
      updatePayload.description = input.description.trim();
    }
    if (input.requiredAura != null) {
      updatePayload.required_aura = Math.max(0, Number(input.requiredAura));
    }
    if (input.link != null) updatePayload.link = input.link.trim();
    if (input.type != null) {
      updatePayload.type = input.type === "hackathon" ? "hackathon" : "event";
    }
    if (input.isActive != null) updatePayload.is_active = input.isActive;

    const { data, error } = await this.client
      .from("events")
      .update(updatePayload)
      .eq("id", eventId)
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at",
      )
      .single();

    if (error) throw error;
    return data;
  }
}
