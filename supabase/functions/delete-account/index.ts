// ═══════════════════════════════════════════════════════════════════
// DELETE-ACCOUNT — Supabase Edge Function
// Deletes the authenticated user's cloud data.
// Soft-deletes all rows, then deletes the auth user.
// Local data on the device is preserved.
// ═══════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    // Get the user's JWT from the request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify the user
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    const now = new Date().toISOString();

    // Soft-delete all user data (order matters for FK constraints)
    const tables = [
      "competition_entries",
      "competition_participants",
      "competitions",
      "reactions",
      "activity_shares",
      "friends",
      "routine_goal_period_statuses",
      "routine_period_statuses",
      "routine_entries",
      "routines",
      "goal_period_statuses",
      "activity_period_statuses",
      "entries",
      "conditions",
      "condition_presets",
      "activities",
      "categories",
      "notifications",
      "user_charts",
      "user_reports",
      "blocked_users",
    ];

    for (const table of tables) {
      await supabase
        .from(table)
        .update({ deleted_at: now })
        .eq("user_id", userId)
        .is_("deleted_at", null);
    }

    // Soft-delete the user profile
    await supabase
      .from("users")
      .update({ deleted_at: now })
      .eq("id", userId);

    // Delete the auth user (hard delete from auth.users)
    const { error: deleteError } = await supabase.auth.admin.deleteUser(userId);

    if (deleteError) {
      console.error("Failed to delete auth user:", deleteError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Account deleted. Local data preserved.",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
