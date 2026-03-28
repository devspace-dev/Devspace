import { PostService } from "../_shared/services/post-service.ts";
import {
  badRequest,
  handleApiError,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import type { SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2";

type CreatePostBody = {
  content?: string;
  tags?: string[];
  imageUrl?: string;
  quotePostId?: string | null;
};

type CommentBody = {
  content?: string;
};

export async function handlePostsRequest(
  request: Request,
  client: SupabaseClient,
  _user: User,
): Promise<Response> {
  const url = new URL(request.url);
  const service = new PostService(client);
  const route = url.pathname.replace(/^.*\/functions\/v1\/posts/, "") || "/";
  const pathParts = route.split("/").filter(Boolean);

  try {
    if (request.method === "GET" && (route === "/" || route === "")) {
      const limit = Number(url.searchParams.get("limit") ?? "20");
      const offset = Number(url.searchParams.get("offset") ?? "0");
      return jsonResponse({ data: await service.listPosts(limit, offset) });
    }

    if (request.method === "POST" && (route === "/" || route === "")) {
      const body = await parseJsonBody<CreatePostBody>(request);
      if (!body.content?.trim() && !body.imageUrl?.trim()) {
        return badRequest("Post content or image is required");
      }

      const data = await service.createPost({
        content: body.content?.trim() ?? "",
        tags: body.tags ?? [],
        imageUrl: body.imageUrl?.trim() ?? "",
        quotePostId: body.quotePostId ?? null,
      });
      return jsonResponse({ data }, { status: 201 });
    }

    if (request.method === "POST" && pathParts.length === 2 && pathParts[1] === "like") {
      return jsonResponse({ data: await service.likePost(pathParts[0]) });
    }

    if (request.method === "DELETE" && pathParts.length === 2 && pathParts[1] === "like") {
      return jsonResponse({ data: await service.unlikePost(pathParts[0]) });
    }

    if (request.method === "POST" &&
      pathParts.length === 2 &&
      pathParts[1] === "comments") {
      const body = await parseJsonBody<CommentBody>(request);
      if (!body.content?.trim()) {
        return badRequest("Comment content is required");
      }

      const data = await service.addComment({
        postId: pathParts[0],
        content: body.content.trim(),
      });
      return jsonResponse({ data }, { status: 201 });
    }

    return methodNotAllowed(request.method);
  } catch (error) {
    return handleApiError(error);
  }
}
