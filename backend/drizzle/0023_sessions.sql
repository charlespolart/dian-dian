CREATE TABLE "ended_sessions" (
	"token_hash" text PRIMARY KEY NOT NULL,
	"reason" text NOT NULL,
	"ended_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "refresh_tokens" ADD COLUMN "replaced_by_id" uuid;--> statement-breakpoint
CREATE INDEX "ended_sessions_ended_at_idx" ON "ended_sessions" USING btree ("ended_at");