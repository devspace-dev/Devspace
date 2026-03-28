import { AuraService } from "../_shared/services/aura-service.ts";
import {
  handleApiError,
  jsonResponse,
  methodNotAllowed,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

export async function handleAuraRequest(
  request: Request,
  client: SupabaseClient,
  user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new AuraService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/aura/, "") || "/";

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      const requestedUserId = url.searchParams.get("userId") ?? user.id;
      return jsonResponse({ data: await service.getSummary(requestedUserId) });
    }

    if (request.method === "POST" && route === "/refresh-streak") {
      return jsonResponse({ data: await service.refreshStreak() });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
