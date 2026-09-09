BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_device_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "ownerId" uuid NOT NULL,
    "token" text NOT NULL,
    "platform" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "freshcart_device_token_unique_idx" ON "freshcart_device_token" USING btree ("token");
CREATE INDEX "freshcart_device_token_owner_idx" ON "freshcart_device_token" USING btree ("ownerId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_list_mute" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "freshcart_list_mute_unique_idx" ON "freshcart_list_mute" USING btree ("listId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_pending_item_notification" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "actorId" uuid NOT NULL,
    "actorName" text NOT NULL,
    "itemName" text NOT NULL,
    "kind" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "freshcart_pending_item_notification_list_idx" ON "freshcart_pending_item_notification" USING btree ("listId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_list_mute"
    ADD CONSTRAINT "freshcart_list_mute_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_pending_item_notification"
    ADD CONSTRAINT "freshcart_pending_item_notification_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20260909154649863', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260909154649863', "timestamp" = now();

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
