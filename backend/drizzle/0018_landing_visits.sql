CREATE TABLE "audience_counts" (
	"day" date NOT NULL,
	"kind" text NOT NULL,
	"store" text DEFAULT '' NOT NULL,
	"origin" text DEFAULT '' NOT NULL,
	"origin_from" text DEFAULT '' NOT NULL,
	"tagged" boolean DEFAULT false NOT NULL,
	"device" text DEFAULT '' NOT NULL,
	"browser" text DEFAULT '' NOT NULL,
	"in_app" text DEFAULT '' NOT NULL,
	"lang" text DEFAULT '' NOT NULL,
	"country" text DEFAULT '' NOT NULL,
	"bot_family" text DEFAULT '' NOT NULL,
	"bot_name" text DEFAULT '' NOT NULL,
	"bot_check" text DEFAULT '' NOT NULL,
	"count" integer NOT NULL,
	CONSTRAINT "audience_counts_pk" PRIMARY KEY("day","kind","store","origin","origin_from","tagged","device","browser","in_app","lang","country","bot_family","bot_name","bot_check")
);
--> statement-breakpoint
CREATE TABLE "audience_months" (
	"month" date PRIMARY KEY NOT NULL,
	"visits" integer DEFAULT 0 NOT NULL,
	"taps_apple" integer DEFAULT 0 NOT NULL,
	"taps_play" integer DEFAULT 0 NOT NULL,
	"bot_hits" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "audience_totals" (
	"day" date PRIMARY KEY NOT NULL,
	"visits" integer DEFAULT 0 NOT NULL,
	"visitors" integer DEFAULT 0 NOT NULL,
	"taps_apple" integer DEFAULT 0 NOT NULL,
	"taps_play" integer DEFAULT 0 NOT NULL
);
