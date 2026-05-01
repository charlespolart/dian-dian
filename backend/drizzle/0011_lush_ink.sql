-- Restores pages.year as a legacy compat column for clients < 1.2.0.
-- Migration 0010 dropped it after copying the value into cells.year, so we
-- pick a representative year back out of cells.year per page. New clients
-- ignore the column; old clients still see the right year on their pages.

-- 1. Add nullable so existing rows survive.
ALTER TABLE "pages" ADD COLUMN "year" integer;--> statement-breakpoint

-- 2. Backfill from cells: the year of the most recent cell on each page.
--    Pages with no cells fall back to the current calendar year.
UPDATE "pages" SET "year" = COALESCE(
  (SELECT "year" FROM "cells" WHERE "cells"."page_id" = "pages"."id" ORDER BY "year" DESC LIMIT 1),
  EXTRACT(YEAR FROM CURRENT_DATE)::integer
);--> statement-breakpoint

-- 3. Lock NOT NULL with a default for any future row created without it.
ALTER TABLE "pages" ALTER COLUMN "year" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "pages" ALTER COLUMN "year" SET DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::integer;
