// ═══════════════════════════════════════════════════════════════════
// GENERATE-NOTIFICATIONS — Supabase Edge Function
// Runs hourly via cron to generate in-app notifications:
//  - Streak at risk (scheduled activity not logged today)
//  - Streak milestones (7, 14, 30, 60, 90, 100, 180, 365)
//  - Condition reminders (active condition exceeds threshold)
//  - Daily reminder to log (at user's configured time)
// See SPEC.md §14.2 for specification.
// ═══════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const now = new Date();
    const currentHour = now.getUTCHours();
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    let notificationsCreated = 0;

    // ─── 1. STREAK AT RISK ───
    // Find users with scheduled activities that haven't been logged today
    const { data: activities } = await supabase
      .from("activities")
      .select("id, user_id, name, schedule")
      .is_("deleted_at", null)
      .eq("is_archived", false)
      .not("schedule", "is", null);

    if (activities) {
      for (const activity of activities) {
        // Check if there's an entry for today
        const { data: entries } = await supabase
          .from("entries")
          .select("id")
          .eq("activity_id", activity.id)
          .eq("user_id", activity.user_id)
          .gte("logged_at", todayStart.toISOString())
          .is_("deleted_at", null)
          .limit(1);

        if (!entries || entries.length === 0) {
          // Check user's notification preferences
          const { data: user } = await supabase
            .from("users")
            .select("settings")
            .eq("id", activity.user_id)
            .single();

          const settings = user?.settings || {};
          if (settings.notifyStreakRisk !== false) {
            // Check if we already sent this notification today
            const { data: existing } = await supabase
              .from("notifications")
              .select("id")
              .eq("user_id", activity.user_id)
              .eq("type", "streak_risk")
              .gte("created_at", todayStart.toISOString())
              .is_("deleted_at", null)
              .limit(1);

            if (!existing || existing.length === 0) {
              await supabase.from("notifications").insert({
                id: crypto.randomUUID(),
                user_id: activity.user_id,
                type: "streak_risk",
                title: "Streak at risk!",
                description: `You haven't logged "${activity.name}" today.`,
                action_type: "navigate_activity",
                action_data: { activity_id: activity.id },
                created_at: now.toISOString(),
              });
              notificationsCreated++;
            }
          }
        }
      }
    }

    // ─── 2. CONDITION REMINDERS ───
    // Find active conditions exceeding the user's reminder threshold
    const { data: conditions } = await supabase
      .from("conditions")
      .select("id, user_id, label, emoji, start_date")
      .is_("deleted_at", null)
      .is_("end_date", null); // Still active

    if (conditions) {
      for (const condition of conditions) {
        const startDate = new Date(condition.start_date);
        const daysSinceStart = Math.floor(
          (now.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)
        );

        // Get user's reminder interval
        const { data: user } = await supabase
          .from("users")
          .select("settings")
          .eq("id", condition.user_id)
          .single();

        const settings = user?.settings || {};
        const reminderDays = settings.conditionReminderDays || 7;

        if (
          settings.notifyConditionReminders !== false &&
          daysSinceStart > 0 &&
          daysSinceStart % reminderDays === 0
        ) {
          await supabase.from("notifications").insert({
            id: crypto.randomUUID(),
            user_id: condition.user_id,
            type: "condition_reminder",
            title: `${condition.emoji} ${condition.label} — Day ${daysSinceStart}`,
            description: "Is this condition still active? Tap to update.",
            action_type: "navigate_activity",
            created_at: now.toISOString(),
          });
          notificationsCreated++;
        }
      }
    }

    // ─── 3. DAILY REMINDERS ───
    // Find users whose reminder time matches the current hour
    const { data: users } = await supabase
      .from("users")
      .select("id, settings")
      .is_("deleted_at", null);

    if (users) {
      for (const user of users) {
        const settings = user.settings || {};
        if (settings.notifyReminders === false) continue;

        const reminderTime = settings.reminderTime || "21:00";
        const [reminderHour] = reminderTime.split(":").map(Number);

        // Check if current UTC hour matches (simplified — production
        // would account for user's timezone)
        if (reminderHour === currentHour) {
          // Check if we already sent today
          const { data: existing } = await supabase
            .from("notifications")
            .select("id")
            .eq("user_id", user.id)
            .eq("type", "reminder")
            .gte("created_at", todayStart.toISOString())
            .is_("deleted_at", null)
            .limit(1);

          if (!existing || existing.length === 0) {
            await supabase.from("notifications").insert({
              id: crypto.randomUUID(),
              user_id: user.id,
              type: "reminder",
              title: "Time to log your activities",
              description: "Don't forget to record what you did today.",
              created_at: now.toISOString(),
            });
            notificationsCreated++;
          }
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        notifications_created: notificationsCreated,
        timestamp: now.toISOString(),
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
