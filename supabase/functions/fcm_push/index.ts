import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { initializeApp, cert } from "npm:firebase-admin/app";
import { getMessaging } from "npm:firebase-admin/messaging";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Lazy initialize Firebase App to prevent re-initialization errors
let firebaseApp: any = null;

serve(async (req) => {
  try {
    const payload = await req.json();

    // Only proceed if a new notification row was inserted
    if (payload.type !== "INSERT" || !payload.record) {
      return new Response("Not an insert event", { status: 200 });
    }

    const notification = payload.record;
    
    // Initialize Firebase if not already done
    if (!firebaseApp) {
      const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
      if (!serviceAccountStr) {
        throw new Error("Missing FIREBASE_SERVICE_ACCOUNT environment variable");
      }
      const serviceAccount = JSON.parse(serviceAccountStr);
      firebaseApp = initializeApp({
        credential: cert(serviceAccount),
      });
    }

    // Connect to Supabase to fetch the recipient's FCM token
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Get the FCM token from the public.users table
    const { data: userData, error: userError } = await supabaseClient
      .from("users")
      .select("fcm_token")
      .eq("id", notification.to_uid)
      .single();

    if (userError || !userData?.fcm_token) {
      console.log(`No FCM token found for user ${notification.to_uid}`);
      return new Response("User has no FCM token", { status: 200 });
    }

    // Determine the push notification title based on the type
    let title = "DevSpace";
    if (notification.type === "like") title = "New Like ⚡";
    if (notification.type === "comment") title = "New Comment 💬";
    if (notification.type === "follow") title = "New Follower 👥";
    if (notification.type === "message") title = "New Message ✉️";
    if (notification.type === "solved") title = "Solution Accepted ✅";
    if (notification.type === "pr_request") title = "Collaboration Request 🤝";

    // Send the notification using Firebase Admin SDK
    const message = {
      notification: {
        title: title,
        body: notification.message,
      },
      data: {
        type: notification.type,
        post_id: notification.post_id || "",
        question_id: notification.question_id || "",
        from_uid: notification.from_uid || "",
      },
      token: userData.fcm_token,
      android: {
        priority: "high",
        notification: {
          channelId: "devspace_high", // Matches your Flutter local channel ID
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await getMessaging().send(message);
    console.log("Successfully sent message:", response);

    return new Response(JSON.stringify({ success: true, response }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    console.error("Error sending push notification:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
