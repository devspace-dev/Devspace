import { EventService } from "../_shared/services/event-service.ts";
import {
  badRequest,
  handleApiError,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

type CreateEventBody = {
  title?: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
  isActive?: boolean;
};

export async function handleEventsRequest(
  request: Request,
  client: SupabaseClient,
  user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new EventService(client);
  const route = url.pathname
    .replace(/^\/functions\/v1\/events/, "")
    .replace(/^\/events/, "") || "/";
  const pathParts = route.split("/").filter(Boolean);

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      const includeInactive = url.searchParams.get("includeInactive") == "true";
      return jsonResponse({ data: await service.listEvents(includeInactive) });
    }

    if (request.method === "GET" && route === "/eligible") {
      return jsonResponse({ data: await service.listEligibleEvents() });
    }

    if (request.method === "POST" && (route === "/" || route === "")) {
      const body = await parseJsonBody<CreateEventBody>(request);
      if (!body.title?.trim()) {
        return badRequest("Event title is required");
      }

      const data = await service.createEvent({
        ...body,
        createdBy: user.id,
      });
      return jsonResponse({ data }, { status: 201 });
    }

    if (request.method === "PATCH" && pathParts.length === 1) {
      const body = await parseJsonBody<CreateEventBody>(request);
      const data = await service.updateEvent(pathParts[0], body);
      return jsonResponse({ data });
    }

    if (request.method === "POST" &&
      pathParts.length === 2 &&
      pathParts[1] === "deactivate") {
      const data = await service.updateEvent(pathParts[0], { isActive: false });
      return jsonResponse({ data });
    }

    if (request.method === "POST" &&
      pathParts.length === 1 &&
      pathParts[0] === "sync-devpost") {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
      const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
        auth: { persistSession: false },
      });
      const adminService = new EventService(serviceClient);
      const data = await adminService.syncHackathons();
      return jsonResponse({ data });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
