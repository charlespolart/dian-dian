ALTER TABLE "cells" ADD COLUMN "created_at" timestamp with time zone DEFAULT now() NOT NULL;--> statement-breakpoint
UPDATE "cells" SET "created_at" = "updated_at";
