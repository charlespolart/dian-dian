CREATE TABLE "deletions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"kind" text NOT NULL,
	"key" text NOT NULL,
	"page_id" uuid,
	"rev" bigint DEFAULT 0 NOT NULL,
	"deleted_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "cells" ADD COLUMN "rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "cells" ADD COLUMN "edit_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "legends" ADD COLUMN "rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "legends" ADD COLUMN "edit_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "pages" ADD COLUMN "rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "pages" ADD COLUMN "edit_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "pages" ADD COLUMN "content_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "pages" ADD COLUMN "legends_order_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "pages_order_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "keep_free_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "theme_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "language_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "cursor_rev" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "deletions" ADD CONSTRAINT "deletions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "deletions_user_rev_idx" ON "deletions" USING btree ("user_id","rev");--> statement-breakpoint
CREATE INDEX "deletions_user_kind_key_idx" ON "deletions" USING btree ("user_id","kind","key");