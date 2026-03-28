import { EventService } from "../_shared/services/event-service.ts";
import {
  badRequest,
  handleApiError,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

type CreateEventBody = {
  title?: string;
  description?: string;
  requiredAura?: number;
  link?: string;
  type?: "hackathon" | "event";
};

export async function handleEventsRequest(
  request: Request,
  client: SupabaseClient,
  user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new EventService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/events/, "") || "/";

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      return jsonResponse({ data: await service.listEvents() });
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

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
