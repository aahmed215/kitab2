-- ═══════════════════════════════════════════════════════════════════
-- Enable Supabase Realtime for tables that use .stream() in the app.
-- This adds tables to the supabase_realtime publication so that
-- INSERT/UPDATE/DELETE changes are broadcast to connected clients.
-- ═══════════════════════════════════════════════════════════════════

-- Enable Realtime on the tables used by stream providers
ALTER PUBLICATION supabase_realtime ADD TABLE activities;
ALTER PUBLICATION supabase_realtime ADD TABLE conditions;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE entries;
ALTER PUBLICATION supabase_realtime ADD TABLE routines;
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- Set REPLICA IDENTITY to FULL so Realtime can send the full row
-- on UPDATE and DELETE events (not just the primary key).
ALTER TABLE activities REPLICA IDENTITY FULL;
ALTER TABLE conditions REPLICA IDENTITY FULL;
ALTER TABLE categories REPLICA IDENTITY FULL;
ALTER TABLE entries REPLICA IDENTITY FULL;
ALTER TABLE routines REPLICA IDENTITY FULL;
ALTER TABLE users REPLICA IDENTITY FULL;
