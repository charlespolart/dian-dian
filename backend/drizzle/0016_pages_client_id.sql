ALTER TABLE "pages" ADD COLUMN "client_id" text;--> statement-breakpoint
CREATE UNIQUE INDEX "pages_user_client_id_idx" ON "pages" USING btree ("user_id","client_id");