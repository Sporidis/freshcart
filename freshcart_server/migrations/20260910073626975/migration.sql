BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "freshcart_shopping_item_list_idx";
ALTER TABLE "freshcart_shopping_item" ADD COLUMN "sortOrder" double precision NOT NULL DEFAULT 0.0;
CREATE INDEX "freshcart_shopping_item_list_idx" ON "freshcart_shopping_item" USING btree ("listId", "sortOrder");

--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20260910073626975', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910073626975', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
