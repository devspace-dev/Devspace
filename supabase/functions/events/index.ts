import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { requireFounderDeviceUser, requireUser } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { handleApiError } from "../_shared/http.ts";
import { handleEventsRequest } from "./controller.ts";

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(request.url);
    const route = url.pathname
      .replace(/^\/functions\/v1\/events/, "")
      .replace(/^\/events/, "") || "/";
    const pathParts = route.split("/").filter(Boolean);
    const includeInactive = url.searchParams.get("includeInactive") == "true";
    const needsAdmin = request.method === "PATCH" ||
      request.method === "GET" && includeInactive ||
      request.method === "POST" &&
        ((route === "/" || route === "") ||
          (pathParts.length === 2 && pathParts[1] === "deactivate") ||
          (route === "/sync-devpost" || route === "sync-devpost"));

    const { client, user } = needsAdmin
      ? await requireFounderDeviceUser(request)
      : await requireUser(request);
    return await handleEventsRequest(request, client, user);
  } catch (error) {
    return handleApiError(error);
  }
});
