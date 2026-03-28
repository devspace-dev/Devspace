import { MissionService } from "../_shared/services/mission-service.ts";
import {
  badRequest,
  handleApiError,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

type MissionType = "coding" | "mcq" | "oneword";

type CreateMissionBody = {
  title?: string;
  type?: MissionType;
  techStack?: string;
  question?: string;
  options?: unknown[];
  correctAnswer?: string;
  link?: string;
  pointsReward?: number;
  publishDate?: string;
  isActive?: boolean;
};

type SubmitMissionBody = {
  answerSubmitted?: string;
  submissionLink?: string;
};

type ReviewMissionBody = {
  isCorrect?: boolean;
};

export async function handleMissionsRequest(
  request: Request,
  client: SupabaseClient,
  _user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new MissionService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/missions/, "") || "/";
  const pathParts = route.split("/").filter(Boolean);

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      const includeInactive = url.searchParams.get("includeInactive") == "true";
      return jsonResponse({ data: await service.listMissions(includeInactive) });
    }

    if (request.method === "GET" && route === "/daily") {
      const techStack = url.searchParams.get("techStack") ?? undefined;
      return jsonResponse({ data: await service.assignDailyMission(techStack) });
    }

    if (request.method === "GET" && route === "/today") {
      return jsonResponse({ data: await service.getTodayAssignment() });
    }

    if (request.method === "POST" && (route === "/" || route === "")) {
      const body = await parseJsonBody<CreateMissionBody>(request);
      if (!body.title?.trim()) {
        return badRequest("Mission title is required");
      }

      if (!body.type) {
        return badRequest("Mission type is required");
      }

      if (!body.question?.trim()) {
        return badRequest("Mission question is required");
      }

      if (!body.publishDate?.trim()) {
        return badRequest("Publish date is required");
      }

      const data = await service.createMission({
        title: body.title,
        type: body.type,
        techStack: body.techStack,
        question: body.question,
        options: body.options,
        correctAnswer: body.correctAnswer,
        link: body.link,
        pointsReward: body.pointsReward,
        publishDate: body.publishDate,
        isActive: body.isActive,
      });

      return jsonResponse({ data }, { status: 201 });
    }

    if (request.method === "POST" && route === "/submit") {
      const body = await parseJsonBody<SubmitMissionBody>(request);
      const data = await service.submitDailyMission(body);
      return jsonResponse({ data });
    }

    if (request.method === "PATCH" && pathParts.length === 1) {
      const body = await parseJsonBody<CreateMissionBody>(request);
      const data = await service.updateMission(pathParts[0], body);
      return jsonResponse({ data });
    }

    if (
      request.method === "POST" &&
      pathParts.length === 2 &&
      pathParts[1] === "deactivate"
    ) {
      const data = await service.updateMission(pathParts[0], { isActive: false });
      return jsonResponse({ data });
    }

    if (
      request.method === "POST" &&
      pathParts.length === 3 &&
      pathParts[0] === "assignments" &&
      pathParts[2] === "review"
    ) {
      const body = await parseJsonBody<ReviewMissionBody>(request);
      if (typeof body.isCorrect !== "boolean") {
        return badRequest("isCorrect must be true or false");
      }

      const data = await service.reviewMissionAssignment(pathParts[1], {
        isCorrect: body.isCorrect,
      });
      return jsonResponse({ data });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
