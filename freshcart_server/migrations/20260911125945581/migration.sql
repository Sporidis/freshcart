BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "freshcart_list_member" ADD COLUMN "avatarColorArgb" bigint;
ALTER TABLE "freshcart_list_member" ADD COLUMN "avatarPhotoUrl" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "freshcart_member_profile" ADD COLUMN "avatarColorArgb" bigint;
ALTER TABLE "freshcart_member_profile" ADD COLUMN "avatarPhotoPath" text;

--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20260911125945581', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260911125945581', "timestamp" = now();

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
