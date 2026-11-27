CREATE TABLE "sync_stats" (
	"week" date NOT NULL,
	"kind" text NOT NULL,
	"count" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "sync_stats_week_kind_pk" PRIMARY KEY("week","kind")
);
--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "sync_floor_rev" bigint DEFAULT 0 NOT NULL;