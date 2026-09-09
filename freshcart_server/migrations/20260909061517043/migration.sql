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
CREATE TABLE "freshcart_list_member" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "displayName" text NOT NULL,
    "role" text NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "freshcart_list_member_unique_idx" ON "freshcart_list_member" USING btree ("listId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_member_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "displayName" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "freshcart_member_profile_auth_user_idx" ON "freshcart_member_profile" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_shop" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "name" text NOT NULL,
    "colorArgb" bigint NOT NULL
);

-- Indexes
CREATE INDEX "freshcart_shop_list_idx" ON "freshcart_shop" USING btree ("listId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_shopping_item" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "listId" uuid NOT NULL,
    "name" text NOT NULL,
    "quantity" bigint NOT NULL,
    "isChecked" boolean NOT NULL,
    "shopId" uuid,
    "note" json,
    "addedBy" uuid NOT NULL,
    "checkedBy" uuid,
    "checkedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "freshcart_shopping_item_list_idx" ON "freshcart_shopping_item" USING btree ("listId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "freshcart_shopping_list" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "name" text NOT NULL,
    "joinCode" text NOT NULL,
    "ownerId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "freshcart_shopping_list_join_code_idx" ON "freshcart_shopping_list" USING btree ("joinCode");
CREATE INDEX "freshcart_shopping_list_owner_idx" ON "freshcart_shopping_list" USING btree ("ownerId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_list_member"
    ADD CONSTRAINT "freshcart_list_member_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_member_profile"
    ADD CONSTRAINT "freshcart_member_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_shop"
    ADD CONSTRAINT "freshcart_shop_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "freshcart_shopping_item"
    ADD CONSTRAINT "freshcart_shopping_item_fk_0"
    FOREIGN KEY("listId")
    REFERENCES "freshcart_shopping_list"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "freshcart_shopping_item"
    ADD CONSTRAINT "freshcart_shopping_item_fk_1"
    FOREIGN KEY("shopId")
    REFERENCES "freshcart_shop"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR freshcart
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('freshcart', '20260909061517043', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260909061517043', "timestamp" = now();

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
