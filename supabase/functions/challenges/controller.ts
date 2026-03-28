import { ChallengeService } from "../_shared/services/challenge-service.ts";
import {
  badRequest,
  handleApiError,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

type CreateChallengeBody = {
  title?: string;
  description?: string;
  difficulty?: "easy" | "medium" | "hard";
  techStack?: string;
  pointsReward?: number;
  isActive?: boolean;
};

type CompleteChallengeBody = {
  submissionText?: string;
  submissionLink?: string;
};

export async function handleChallengesRequest(
  request: Request,
  client: SupabaseClient,
  _user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new ChallengeService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/challenges/, "") || "/";
  const pathParts = route.split("/").filter(Boolean);

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      const includeInactive = url.searchParams.get("includeInactive") == "true";
      return jsonResponse({ data: await service.listChallenges(includeInactive) });
    }

    if (request.method === "GET" && route === "/daily") {
      const techStack = url.searchParams.get("techStack") ?? undefined;
      return jsonResponse({ data: await service.assignDailyChallenge(techStack) });
    }

    if (request.method === "GET" && route === "/today") {
      return jsonResponse({ data: await service.getTodayAssignment() });
    }

    if (request.method === "POST" && (route === "/" || route === "")) {
      const body = await parseJsonBody<CreateChallengeBody>(request);
      if (!body.title?.trim()) {
        return badRequest("Challenge title is required");
      }

      const data = await service.createChallenge(body);
      return jsonResponse({ data }, { status: 201 });
    }

    if (request.method === "POST" && route === "/complete") {
      const body = await parseJsonBody<CompleteChallengeBody>(request);
      if (!body.submissionText?.trim() && !body.submissionLink?.trim()) {
        return badRequest("Submission text or link is required");
      }

      const data = await service.completeDailyChallenge(body);
      return jsonResponse({ data });
    }

    if (request.method === "PATCH" && pathParts.length === 1) {
      const body = await parseJsonBody<CreateChallengeBody>(request);
      const data = await service.updateChallenge(pathParts[0], body);
      return jsonResponse({ data });
    }

    if (request.method === "POST" &&
      pathParts.length === 2 &&
      pathParts[1] === "deactivate") {
      const data = await service.updateChallenge(pathParts[0], { isActive: false });
      return jsonResponse({ data });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
