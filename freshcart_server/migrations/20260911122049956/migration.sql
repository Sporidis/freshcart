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
CREATE TABLE "freshcart_item_name_history" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "name" text NOT NULL,
    "lastUsedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "freshcart_item_name_history_list_idx" ON "freshcart_item_name_history" USING btree ("listId", "lastUsedAt");
CREATE UNIQUE INDEX "freshcart_item_name_history_unique_idx" ON "freshcart_item_name_history" USING btree ("listId", "name");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_item_name_history"
    ADD CONSTRAINT "freshcart_item_name_history_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20260911122049956', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260911122049956', "timestamp" = now();

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
