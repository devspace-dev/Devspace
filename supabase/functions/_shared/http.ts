import { corsHeaders } from "./cors.ts";

export function jsonResponse(
  body: unknown,
  init: ResponseInit = {},
): Response {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json");

  for (const [key, value] of Object.entries(corsHeaders)) {
    headers.set(key, value);
  }

  return new Response(JSON.stringify(body), {
    ...init,
    headers,
  });
}

export function noContentResponse(): Response {
  return new Response("ok", {
    status: 204,
    headers: corsHeaders,
  });
}

export async function parseJsonBody<T>(request: Request): Promise<T> {
  const rawBody = await request.text();
  if (!rawBody.trim()) {
    return {} as T;
  }

  return JSON.parse(rawBody) as T;
}

export function badRequest(message: string): Response {
  return jsonResponse({ error: message }, { status: 400 });
}

export function unauthorized(message = "Unauthorized"): Response {
  return jsonResponse({ error: message }, { status: 401 });
}

export function methodNotAllowed(method: string): Response {
  return jsonResponse(
    { error: `Method ${method} is not allowed for this route.` },
    { status: 405 },
  );
}

export function handleApiError(error: unknown): Response {
  const message = error instanceof Error ? error.message : "Unexpected error";
  const status = /unauthorized|authentication required/i.test(message)
    ? 401
    : /rate limit/i.test(message)
    ? 429
    : /not found/i.test(message)
    ? 404
    : /already|required|invalid|cannot/i.test(message)
    ? 400
    : 500;

  return jsonResponse({ error: message }, { status });
}
