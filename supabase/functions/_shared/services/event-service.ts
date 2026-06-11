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

  private parseDevpostDate(dateStr: string) {
    if (!dateStr) return null;
    const parts = dateStr.split("-");
    const targetStr = parts.length > 1 ? parts[1].trim() : dateStr.trim();
    const parsed = Date.parse(targetStr);
    if (!isNaN(parsed)) {
      return new Date(parsed).toISOString();
    }
    const currentYear = new Date().getFullYear();
    const fallbackParsed = Date.parse(`${targetStr}, ${currentYear}`);
    if (!isNaN(fallbackParsed)) {
      return new Date(fallbackParsed).toISOString();
    }
    return null;
  }

  private async fetchDevpost() {
    const hackathons: any[] = [];
    try {
      console.log("Fetching from Devpost API...");
      const response = await fetch("https://devpost.com/api/hackathons", {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "application/json",
        },
      });
      if (!response.ok) {
        throw new Error(`Devpost API returned status ${response.status}`);
      }
      const json = await response.json();
      const items = json.hackathons || [];
      for (const hack of items) {
        const title = hack.title || "";
        const link = hack.url || "";
        if (!title || !link) continue;

        let bannerUrl = hack.thumbnail_url || "";
        if (bannerUrl.startsWith("//")) {
          bannerUrl = "https:" + bannerUrl;
        }
        if (!bannerUrl) {
          bannerUrl = "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=1000";
        }

        const organizer = hack.organization_name || "Devpost Sponsor";
        const dateText = hack.submission_period_dates || "";
        const locationText = hack.displayed_location?.location || "Online";
        
        const themesList = (hack.themes || []).map((t: any) => t.name).join(", ");
        const description = `Themes: ${themesList || "General Hackathon"}. Check out this exciting hackathon from Devpost! Time left to submit: ${hack.time_left_to_submission || "Open"}.`;

        let endDate = null;
        if (dateText) {
          endDate = this.parseDevpostDate(dateText);
        }

        hackathons.push({
          title,
          link,
          banner_url: bannerUrl,
          organizer,
          date: dateText,
          location: locationText,
          description,
          end_date: endDate
        });
      }
    } catch (e) {
      console.error("Error fetching Devpost hackathons:", e);
    }
    return hackathons;
  }

  private async fetchDevfolio() {
    const hackathons: any[] = [];
    try {
      console.log("Fetching from Devfolio public page...");
      const response = await fetch("https://devfolio.co/hackathons", {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          "Accept-Language": "en-US,en;q=0.5",
        },
      });
      if (!response.ok) {
        throw new Error(`Devfolio page returned status ${response.status}`);
      }
      const html = await response.text();
      const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
      if (!match) {
        throw new Error("Failed to find __NEXT_DATA__ on Devfolio page");
      }
      const data = JSON.parse(match[1]);
      const queries = data.props?.pageProps?.dehydratedState?.queries || [];
      let openHacks: any[] = [];
      let upcomingHacks: any[] = [];
      for (const q of queries) {
        const qData = q.state?.data;
        if (qData) {
          if (qData.open_hackathons) openHacks = qData.open_hackathons;
          if (qData.upcoming_hackathons) upcomingHacks = qData.upcoming_hackathons;
        }
      }
      const devfolioHacks = [...openHacks, ...upcomingHacks];
      
      for (const hack of devfolioHacks) {
        const title = hack.name || "";
        const slug = hack.slug || "";
        if (!title || !slug) continue;

        const link = `https://${slug}.devfolio.co`;

        let bannerUrl = hack.settings?.featured_cover_img_v2 || hack.settings?.featured_cover_img || "";
        if (bannerUrl) {
          if (!bannerUrl.startsWith("http://") && !bannerUrl.startsWith("https://")) {
            if (bannerUrl.startsWith("/")) {
              bannerUrl = `https://assets.devfolio.co${bannerUrl}`;
            } else {
              bannerUrl = `https://assets.devfolio.co/${bannerUrl}`;
            }
          }
        } else {
          bannerUrl = "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=1000";
        }

        const organizer = "Devfolio";
        const isOnline = hack.is_online === true;
        const locationText = isOnline ? "Online" : "In-person";
        
        const themesList = (hack.themes || []).map((t: any) => t.theme?.name || "").filter(Boolean).join(", ");
        const description = `Themes: ${themesList || "General Hackathon"}. Mode: ${locationText}. Check out this exciting hackathon from Devfolio!`;

        const startDate = hack.starts_at ? new Date(hack.starts_at) : null;
        const endDateVal = hack.ends_at ? new Date(hack.ends_at) : null;
        let dateText = "";
        if (startDate && endDateVal) {
          dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
        } else if (endDateVal) {
          dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
        }

        let endDate = hack.settings?.reg_ends_at || hack.ends_at || null;
        if (endDate) {
          endDate = new Date(endDate).toISOString();
        }

        hackathons.push({
          title,
          link,
          banner_url: bannerUrl,
          organizer,
          date: dateText,
          location: locationText,
          description,
          end_date: endDate
        });
      }
    } catch (e) {
      console.error("Error fetching Devfolio hackathons:", e);
    }
    return hackathons;
  }

  private async fetchUnstop() {
    const hackathons: any[] = [];
    try {
      console.log("Fetching from Unstop API...");
      const response = await fetch("https://unstop.com/api/public/opportunity/search-result?opportunity=hackathons&page=1", {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "application/json",
        },
      });
      if (!response.ok) {
        throw new Error(`Unstop API returned status ${response.status}`);
      }
      const json = await response.json();
      const items = json.data?.data || [];
      
      for (const hack of items) {
        const title = hack.title || "";
        const publicUrl = hack.public_url || "";
        if (!title || !publicUrl) continue;

        const link = hack.seo_url || `https://unstop.com/${publicUrl}`;
        const bannerUrl = hack.logoUrl2 || "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=1000";
        const organizer = hack.organisation?.name || "Unstop";
        const locationText = hack.region || "Online";
        
        const rawDesc = hack.details ? hack.details.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim() : "";
        const description = rawDesc || `Join ${title} on Unstop!`;

        const startDate = hack.regnRequirements?.start_regn_dt ? new Date(hack.regnRequirements.start_regn_dt) : null;
        const endDateVal = hack.end_date ? new Date(hack.end_date) : null;
        let dateText = "";
        if (startDate && endDateVal) {
          dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
        } else if (endDateVal) {
          dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
        }

        let endDate = hack.end_date || null;
        if (endDate) {
          endDate = new Date(endDate).toISOString();
        }

        hackathons.push({
          title,
          link,
          banner_url: bannerUrl,
          organizer,
          date: dateText,
          location: locationText,
          description,
          end_date: endDate
        });
      }
    } catch (e) {
      console.error("Error fetching Unstop hackathons:", e);
    }
    return hackathons;
  }

  async syncHackathons() {
    console.log("Starting unified hackathon synchronization in Edge Function...");
    
    const [devpostHacks, devfolioHacks, unstopHacks] = await Promise.all([
      this.fetchDevpost(),
      this.fetchDevfolio(),
      this.fetchUnstop()
    ]);

    const allHacks = [...devpostHacks, ...devfolioHacks, ...unstopHacks];
    console.log(`Total active hackathons fetched: ${allHacks.length}`);

    let newCount = 0;
    let updatedCount = 0;

    for (const hack of allHacks) {
      const result = await this.upsertEvent(hack);
      if (result === "inserted") {
        newCount++;
      } else if (result === "updated") {
        updatedCount++;
      }
    }

    const deletedCount = await this.cleanExpiredEvents();

    return {
      newCount,
      updatedCount,
      deletedCount,
      totalFetched: allHacks.length,
      breakdown: {
        devpost: devpostHacks.length,
        devfolio: devfolioHacks.length,
        unstop: unstopHacks.length
      }
    };
  }

  private async upsertEvent(eventData: any, includeEndDate = true): Promise<string | boolean> {
    const { link, title } = eventData;
    if (!link || !title) return false;

    const { data: existing, error: checkError } = await this.client
      .from("events")
      .select("id")
      .eq("link", link)
      .maybeSingle();

    if (checkError) {
      console.error(`Error checking event for link ${link}:`, checkError);
      return false;
    }

    const payload: Record<string, any> = {
      title: eventData.title,
      description: eventData.description,
      banner_url: eventData.banner_url,
      date: eventData.date,
      location: eventData.location,
      organizer: eventData.organizer,
      updated_at: new Date().toISOString()
    };

    if (includeEndDate && eventData.end_date) {
      payload.end_date = eventData.end_date;
    }

    if (existing) {
      const { error: updateError } = await this.client
        .from("events")
        .update(payload)
        .eq("id", existing.id);

      if (updateError) {
        if (includeEndDate && (updateError.code === "PGRST204" || updateError.message?.includes("end_date"))) {
          console.warn(`Warning: end_date column not found in schema. Retrying update without end_date...`);
          return await this.upsertEvent(eventData, false);
        }
        console.error(`Error updating event ${existing.id}:`, updateError);
        return false;
      }
      return "updated";
    } else {
      const insertPayload = {
        ...payload,
        required_aura: 0,
        link: eventData.link,
        type: "hackathon",
        is_active: true
      };
      delete insertPayload.updated_at;

      const { error: insertError } = await this.client
        .from("events")
        .insert(insertPayload);

      if (insertError) {
        if (includeEndDate && (insertError.code === "PGRST204" || insertError.message?.includes("end_date"))) {
          console.warn(`Warning: end_date column not found in schema. Retrying insert without end_date...`);
          return await this.upsertEvent(eventData, false);
        }
        console.error(`Error inserting event "${title}":`, insertError);
        return false;
      }
      return "inserted";
    }
  }

  private async cleanExpiredEvents() {
    console.log("Cleaning up expired events...");
    try {
      const { data: expiredEvents, error: expiredError } = await this.client
        .from("events")
        .select("id")
        .eq("type", "hackathon")
        .lt("end_date", new Date().toISOString());

      if (expiredError) {
        if (expiredError.code === "PGRST204" || expiredError.message?.includes("end_date")) {
          console.warn("Skipping cleanup: end_date column does not exist in events table yet.");
          return 0;
        }
        console.error("Error fetching expired events:", expiredError);
        return 0;
      }

      if (expiredEvents && expiredEvents.length > 0) {
        const expiredIds = expiredEvents.map((e: any) => e.id);
        
        const { error: userEventsDeleteError } = await this.client
          .from("user_events")
          .delete()
          .in("event_id", expiredIds);
        
        if (userEventsDeleteError) {
          console.error("Error deleting user_events for expired events:", userEventsDeleteError);
        }

        const { error: eventsDeleteError } = await this.client
          .from("events")
          .delete()
          .in("id", expiredIds);

        if (eventsDeleteError) {
          console.error("Error deleting expired events:", eventsDeleteError);
          return 0;
        }
        
        console.log(`Successfully deleted ${expiredIds.length} expired hackathons.`);
        return expiredIds.length;
      }
    } catch (e) {
      console.error("Exception cleaning up expired hackathons:", e);
    }
    return 0;
  }
}
