CREATE TABLE "subscription_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"rc_event_id" text NOT NULL,
	"user_id" uuid,
	"type" text NOT NULL,
	"environment" text,
	"store" text,
	"product_id" text,
	"period_type" text,
	"price_usd" double precision,
	"price_local" double precision,
	"currency" text,
	"country_code" text,
	"cancel_reason" text,
	"expiration_reason" text,
	"is_trial_conversion" boolean,
	"original_transaction_id" text,
	"event_at" timestamp with time zone NOT NULL,
	"purchased_at" timestamp with time zone,
	"expires_at" timestamp with time zone,
	"payload" jsonb NOT NULL,
	"received_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "subscription_events_rc_event_id_unique" UNIQUE("rc_event_id")
);
--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "platform" text;--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "app_version" text;--> statement-breakpoint
ALTER TABLE "subscription_events" ADD CONSTRAINT "subscription_events_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "subscription_events_user_id_idx" ON "subscription_events" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "subscription_events_type_event_at_idx" ON "subscription_events" USING btree ("type","event_at");