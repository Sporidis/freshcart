BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "freshcart_list_member" DROP COLUMN "displayName";
ALTER TABLE "freshcart_list_member" DROP COLUMN "avatarColorArgb";
ALTER TABLE "freshcart_list_member" DROP COLUMN "avatarPhotoUrl";

--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20261001150005278', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001150005278', "timestamp" = now();

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
