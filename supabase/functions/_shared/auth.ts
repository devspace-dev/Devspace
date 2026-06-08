import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function bearerToken(request: Request): string | null {
  const authorization = request.headers.get("Authorization") ?? "";
  const [scheme, token] = authorization.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    return null;
  }

  return token;
}

export function createAuthorizedClient(request: Request) {
  const token = bearerToken(request);
  if (!token) {
    throw new Error("Unauthorized");
  }

  return createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false },
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  });
}

export async function requireUser(request: Request) {
  const client = createAuthorizedClient(request);
  const { data, error } = await client.auth.getUser();

  if (error || !data.user) {
    throw new Error("Unauthorized");
  }

  return { client, user: data.user };
}

export async function requireAdminUser(request: Request) {
  const { client, user } = await requireUser(request);
  const { data, error } = await client
    .from("users")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  if (error || data?.is_admin !== true) {
    throw new Error("Unauthorized");
  }

  return { client, user };
}

export function founderDeviceIdFromRequest(request: Request): string | null {
  const deviceId = request.headers.get("X-Device-Id")?.trim() ?? "";
  return deviceId || null;
}

export async function requireFounderDeviceUser(request: Request) {
  const { client, user } = await requireAdminUser(request);
  const deviceId = founderDeviceIdFromRequest(request);

  if (!deviceId) {
    throw new Error("Founder device ID is required");
  }

  // Create a service client to bypass RLS and perform safe checks/inserts on founder_devices
  const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  const { data, error } = await serviceClient
    .from("founder_devices")
    .select("device_id, is_active")
    .eq("user_id", user.id)
    .eq("device_id", deviceId)
    .maybeSingle();

  if (error) {
    console.error("Error checking founder device:", error);
    throw new Error("This device is not allowed to use founder tools");
  }

  if (!data) {
    // Automatically allowlist and register device for this verified admin/founder
    const { error: insertError } = await serviceClient
      .from("founder_devices")
      .insert({
        user_id: user.id,
        device_id: deviceId,
        is_active: true,
        label: "Auto-registered Admin Device",
      });

    if (insertError) {
      console.error("Auto-registration of device failed:", insertError);
      throw new Error("This device is not allowed to use founder tools");
    }
  } else if (data.is_active !== true) {
    throw new Error("This device is not allowed to use founder tools");
  }

  return { client, user, deviceId };
}
