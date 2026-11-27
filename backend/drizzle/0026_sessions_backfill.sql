-- Every refresh token issued before sessions existed becomes a session of
-- its own (chantier 9): production has no chains of renewals yet
-- (replaced_by_id is not released), so one token is one phone.
-- A random id per token, so that two tokens never share a session.
CREATE TEMP TABLE token_sessions AS
  SELECT id AS token_id, user_id, gen_random_uuid() AS session_id, created_at
  FROM refresh_tokens WHERE session_id IS NULL;--> statement-breakpoint
INSERT INTO sessions (id, user_id, created_at)
  SELECT session_id, user_id, created_at FROM token_sessions;--> statement-breakpoint
UPDATE refresh_tokens r SET session_id = t.session_id
  FROM token_sessions t WHERE r.id = t.token_id;--> statement-breakpoint
DROP TABLE token_sessions;
