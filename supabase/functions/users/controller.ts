import { UserService } from "../_shared/services/user-service.ts";
import {
  handleApiError,
  jsonResponse,
  methodNotAllowed,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

export async function handleUsersRequest(
  request: Request,
  client: SupabaseClient,
  _user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new UserService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/users/, "") || "/";

  try {
    if (request.method === "GET" && (route === "/me" || route === "/")) {
      return jsonResponse({ data: await service.getCurrentUserProfile() });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
