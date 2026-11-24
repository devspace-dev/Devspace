import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreateEventInput = {
  title: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  createdBy?: string;
  bannerUrl?: string;
  date?: string;
  endDate?: string;
  location?: string;
  organizer?: string;
};

type UpdateEventInput = {
  title?: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  isActive?: boolean;
  bannerUrl?: string;
  date?: string;
  endDate?: string;
  location?: string;
  organizer?: string;
};

export class EventService {
  constructor(private readonly client: SupabaseClient) {}

  async listEvents(includeInactive = false) {
    let query = this.client
      .from("events")
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at, banner_url, date, end_date, location, organizer",
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
        banner_url: input.bannerUrl?.trim() ?? null,
        date: input.date?.trim() ?? null,
        end_date: input.endDate?.trim() ?? null,
        location: input.location?.trim() ?? null,
        organizer: input.organizer?.trim() ?? null,
      })
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at, banner_url, date, end_date, location, organizer",
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
    if (input.bannerUrl != null) updatePayload.banner_url = input.bannerUrl.trim();
    if (input.date != null) updatePayload.date = input.date.trim();
    if (input.endDate !== undefined) {
      updatePayload.end_date = input.endDate?.trim() || null;
    }
    if (input.location != null) updatePayload.location = input.location.trim();
    if (input.organizer != null) updatePayload.organizer = input.organizer.trim();

    const { data, error } = await this.client
      .from("events")
      .update(updatePayload)
      .eq("id", eventId)
      .select(
        "id, title, description, required_aura, link, type, is_active, created_at, banner_url, date, end_date, location, organizer",
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
        if (bannerUrl) {
          if (bannerUrl.includes("medium_square")) {
            bannerUrl = bannerUrl.replace("medium_square", "original");
          }
          if (bannerUrl.startsWith("//")) {
            bannerUrl = "https:" + bannerUrl;
          }
        }
        if (!bannerUrl) {
          bannerUrl = null;
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
        const tz = hack?.timezone;
        if (tz && tz !== "Asia/Kolkata" && tz !== "Asia/Calcutta") continue;

        const link = `https://${slug}.devfolio.co`;

        let bannerUrl = hack.settings?.featured_cover_img_v2 || hack.settings?.featured_cover_img || "";
        if (!bannerUrl && slug) {
          try {
            const subRes = await fetch(`https://${slug}.devfolio.co/`, {
              headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
              }
            });
            if (subRes.ok) {
              const subHtml = await subRes.text();
              const subMatch = subHtml.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
              if (subMatch) {
                const subData = JSON.parse(subMatch[1]);
                const hackObj = subData.props?.pageProps?.hackathon;
                if (hackObj?.cover_img) {
                  bannerUrl = hackObj.cover_img;
                }
              }
            }
          } catch (err) {
            console.error(`Failed to fetch cover image for Devfolio hackathon ${slug}:`, err);
          }
        }

        if (bannerUrl) {
          if (!bannerUrl.startsWith("http://") && !bannerUrl.startsWith("https://")) {
            if (bannerUrl.startsWith("/")) {
              bannerUrl = `https://assets.devfolio.co${bannerUrl}`;
            } else {
              bannerUrl = `https://assets.devfolio.co/${bannerUrl}`;
            }
          }
        } else {
          bannerUrl = null;
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

  private isIndianUnstopOpportunity(opp: any): boolean {
    if (opp?.region === "online") return true;
    if (!opp?.address_with_country_logo?.country) return true;
    return opp?.address_with_country_logo?.country?.name === "India";
  }

  private isTechBTechInternship(opp: any): boolean {
    const title = (opp?.title || "").trim();
    if (!title) return false;
    const techRegex = /\b(software|developer|frontend|front-end|backend|back-end|full\s*stack|web|android|flutter|ios|mobile|ai|ml|machine\s*learning|deep\s*learning|data\s*(science|analyst|engineer|analytics)|python|java|javascript|react|node|cloud|devops|security|cyber|qa|sde|engineer|embedded|iot|blockchain|web3|solidity|tech)\b/i;
    const nonTechRegex = /\b(sales|business\s*development|bde|marketing|content|writer|copywriting|seo|telecaller|calling|counselor|graphic\s*design|video\s*editor|hr|human\s*resource|talent|recruiter|finance|accounting|lawyer|legal|operations|lead\s*generation|campus\s*ambassador)\b/i;
    if (!techRegex.test(title)) return false;
    if (nonTechRegex.test(title)) return false;
    const filters = opp?.filters || [];
    if (filters.length > 0) {
      const filterNames = filters.map((f: any) => (f?.name || "").toLowerCase());
      const isEng = filterNames.some((n: string) => n.includes("engineering") || n.includes("undergraduate") || n.includes("fresher") || n.includes("all"));
      if (!isEng) return false;
    }
    return true;
  }

  private unstopLocationText(opp: any): string {
    if (opp?.region === "online") return "Online";
    const addr = opp?.address_with_country_logo;
    const place = [addr?.city, addr?.state].filter(Boolean).join(", ");
    if (place) return place;
    if (opp?.region === "hybrid") return "Hybrid";
    return "In-person";
  }

  private async fetchUnstopHackathons(maxPages = 2, perPage = 50) {
    const hackathons: any[] = [];
    const seenLinks = new Set<string>();
    for (let page = 1; page <= maxPages; page++) {
      try {
        console.log(`Fetching Unstop hackathons page ${page}...`);
        const response = await fetch(`https://unstop.com/api/public/opportunity/search-result?opportunity=hackathons&eligible=engineering-students&per_page=${perPage}&page=${page}`, {
          headers: {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "application/json",
          },
        });
        if (!response.ok) break;
        const json = await response.json();
        const items = json.data?.data || [];
        if (items.length === 0) break;
        
        for (const hack of items) {
          const title = hack.title?.trim() || "";
          const publicUrl = hack.public_url || "";
          if (!title || !publicUrl) continue;
          if (!this.isIndianUnstopOpportunity(hack)) continue;

          const link = hack.seo_url || `https://unstop.com/${publicUrl}`;
          if (seenLinks.has(link)) continue;
          seenLinks.add(link);

          const bannerUrl = hack.logoUrl2 || hack.banner_mobile || null;
          const organizer = hack.organisation?.name || "Unstop";
          const locationText = this.unstopLocationText(hack);
          
          let rawDesc = hack.details ? hack.details.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim() : "";
          if (rawDesc.length > 250) {
            rawDesc = rawDesc.substring(0, 247) + "...";
          }
          const description = rawDesc || `Join ${title} organized by ${organizer} on Unstop!`;

          const startDate = hack.regnRequirements?.start_regn_dt ? new Date(hack.regnRequirements.start_regn_dt) : null;
          const endDateVal = hack.end_date ? new Date(hack.end_date) : null;
          let dateText = "";
          if (startDate && endDateVal) {
            dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
          } else if (endDateVal) {
            dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
          }

          let endDate = hack.end_date || hack.regnRequirements?.end_regn_dt || null;
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
            end_date: endDate,
            type: "hackathon"
          });
        }
      } catch (e) {
        console.error("Error fetching Unstop hackathons:", e);
        break;
      }
    }
    return hackathons;
  }

  private async fetchUnstopInternships() {
    const internships: any[] = [];
    const seenLinks = new Set<string>();
    const terms = ["developer", "software"];

    for (const term of terms) {
      for (let page = 1; page <= 2; page++) {
        try {
          console.log(`Fetching Unstop tech internships term="${term}", page=${page}...`);
          const response = await fetch(`https://unstop.com/api/public/opportunity/search-result?opportunity=internships&searchTerm=${encodeURIComponent(term)}&per_page=30&page=${page}`, {
            headers: {
              "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
              "Accept": "application/json",
            },
          });
          if (!response.ok) break;
          const json = await response.json();
          const items = json.data?.data || [];
          if (items.length === 0) break;

          for (const item of items) {
            const title = item.title?.trim() || "";
            const publicUrl = item.public_url || "";
            if (!title || !publicUrl) continue;
            if (!this.isIndianUnstopOpportunity(item)) continue;
            if (!this.isTechBTechInternship(item)) continue;

            const link = item.seo_url || `https://unstop.com/${publicUrl}`;
            if (seenLinks.has(link)) continue;
            seenLinks.add(link);

            const bannerUrl = item.logoUrl2 || item.banner_mobile || null;
            const organizer = item.organisation?.name || "Unstop";
            const locationText = this.unstopLocationText(item);

            let rawDesc = item.details ? item.details.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim() : "";
            if (rawDesc.length > 250) {
              rawDesc = rawDesc.substring(0, 247) + "...";
            }
            const description = rawDesc || `Apply for ${title} at ${organizer} on Unstop!`;

            const startDate = item.regnRequirements?.start_regn_dt ? new Date(item.regnRequirements.start_regn_dt) : null;
            const endDateVal = item.end_date ? new Date(item.end_date) : null;
            let dateText = "";
            if (startDate && endDateVal) {
              dateText = `${startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} - ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
            } else if (endDateVal) {
              dateText = `Closes ${endDateVal.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`;
            }

            let endDate = item.end_date || item.regnRequirements?.end_regn_dt || null;
            if (endDate) {
              endDate = new Date(endDate).toISOString();
            }

            internships.push({
              title,
              link,
              banner_url: bannerUrl,
              organizer,
              date: dateText,
              location: locationText,
              description,
              end_date: endDate,
              type: "internship"
            });
          }
        } catch (e) {
          console.error("Error fetching Unstop internships:", e);
          break;
        }
      }
    }
    return internships;
  }

  async syncHackathons() {
    console.log("Starting unified India-optimized opportunities synchronization in Edge Function...");
    
    const [devfolioHacks, unstopHacks, unstopInternships] = await Promise.all([
      this.fetchDevfolio(),
      this.fetchUnstopHackathons(2, 50),
      this.fetchUnstopInternships()
    ]);

    const allOpportunities = [...devfolioHacks, ...unstopHacks, ...unstopInternships];
    console.log(`Total active India opportunities fetched: ${allOpportunities.length} (Devfolio: ${devfolioHacks.length}, Unstop Hacks: ${unstopHacks.length}, Unstop Internships: ${unstopInternships.length})`);

    let newCount = 0;
    let updatedCount = 0;

    for (const item of allOpportunities) {
      const result = await this.upsertEvent(item);
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
      totalFetched: allOpportunities.length,
      breakdown: {
        devfolio: devfolioHacks.length,
        unstopHackathons: unstopHacks.length,
        unstopInternships: unstopInternships.length
      }
    };
  }

  private async upsertEvent(eventData: any, includeEndDate = true, fallbackType = false): Promise<string | boolean> {
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
          return await this.upsertEvent(eventData, false, fallbackType);
        }
        console.error(`Error updating event ${existing.id}:`, updateError);
        return false;
      }
      return "updated";
    } else {
      const typeToUse = fallbackType ? "event" : (eventData.type || "hackathon");
      const insertPayload = {
        ...payload,
        required_aura: 0,
        link: eventData.link,
        type: typeToUse,
        is_active: true
      };
      delete insertPayload.updated_at;

      const { error: insertError } = await this.client
        .from("events")
        .insert(insertPayload);

      if (insertError) {
        if (includeEndDate && (insertError.code === "PGRST204" || insertError.message?.includes("end_date"))) {
          console.warn(`Warning: end_date column not found in schema. Retrying insert without end_date...`);
          return await this.upsertEvent(eventData, false, fallbackType);
        }
        if (!fallbackType && (insertError.code === "23514" || insertError.message?.includes("events_type_check"))) {
          console.warn(`Warning: events_type_check constraint does not allow "${eventData.type}". Retrying with type="event"...`);
          return await this.upsertEvent(eventData, includeEndDate, true);
        }
        console.error(`Error inserting event "${title}":`, insertError);
        return false;
      }
      return "inserted";
    }
  }

  private async cleanExpiredEvents() {
    console.log("Cleaning up expired events and internships...");
    try {
      const { data: expiredEvents, error: expiredError } = await this.client
        .from("events")
        .select("id")
        .in("type", ["hackathon", "internship", "event"])
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
        
        console.log(`Successfully deleted ${expiredIds.length} expired opportunities.`);
        return expiredIds.length;
      }
    } catch (e) {
      console.error("Exception cleaning up expired opportunities:", e);
    }
    return 0;
  }
}
