-- Multi-year refactor: trackers become year-agnostic; cells gain a year column.
-- Done in 4 steps inside a transaction so existing data is preserved safely.

-- 1. Add cells.year as nullable so existing rows survive the ALTER.
ALTER TABLE "cells" ADD COLUMN "year" smallint;--> statement-breakpoint

-- 2. Backfill cells.year from pages.year for every existing cell.
UPDATE "cells" SET "year" = "pages"."year" FROM "pages" WHERE "cells"."page_id" = "pages"."id";--> statement-breakpoint

-- 3. Now that everything is filled, lock it down + swap the primary key.
ALTER TABLE "cells" ALTER COLUMN "year" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "cells" DROP CONSTRAINT "cells_page_id_month_day_pk";--> statement-breakpoint
ALTER TABLE "cells" ADD CONSTRAINT "cells_page_id_year_month_day_pk" PRIMARY KEY("page_id","year","month","day");--> statement-breakpoint
CREATE INDEX "cells_page_year_idx" ON "cells" ("page_id","year");--> statement-breakpoint

-- 4. Drop the now-unused pages.year column.
ALTER TABLE "pages" DROP COLUMN "year";
