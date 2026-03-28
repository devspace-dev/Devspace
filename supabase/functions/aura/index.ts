import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { requireUser } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { handleApiError } from "../_shared/http.ts";
import { handleAuraRequest } from "./controller.ts";

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { client, user } = await requireUser(request);
    return await handleAuraRequest(request, client, user);
  } catch (error) {
    return handleApiError(error);
  }
});
