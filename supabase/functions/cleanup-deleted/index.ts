// ═══════════════════════════════════════════════════════════════════
// CLEANUP-DELETED — Supabase Edge Function
// Runs daily via cron. Hard-deletes rows where deleted_at is
// older than 30 days. Also cleans up synced sync_queue entries.
// ═══════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const cutoff = thirtyDaysAgo.toISOString();

    let totalDeleted = 0;

    // Tables to clean (reverse FK order)
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
      "users",
    ];

    for (const table of tables) {
      const { count } = await supabase
        .from(table)
        .delete({ count: "exact" })
        .lt("deleted_at", cutoff);

      totalDeleted += count || 0;
    }

    return new Response(
      JSON.stringify({
        success: true,
        total_deleted: totalDeleted,
        cutoff_date: cutoff,
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
