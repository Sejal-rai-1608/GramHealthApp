/*
  Warnings:

  - A unique constraint covering the columns `[abha_id]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterEnum
ALTER TYPE "UserRole" ADD VALUE 'PHARMACY';

-- AlterTable
ALTER TABLE "consultations" ADD COLUMN     "voice_note_duration" INTEGER,
ADD COLUMN     "voice_note_url" TEXT;

-- AlterTable
ALTER TABLE "medical_records" ADD COLUMN     "document_type" VARCHAR(50),
ADD COLUMN     "file_url" TEXT,
ADD COLUMN     "issued_date" TIMESTAMP(3),
ADD COLUMN     "source" VARCHAR(50) DEFAULT 'MANUAL',
ADD COLUMN     "title" VARCHAR(255);

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "abha_id" VARCHAR(50);

-- CreateTable
CREATE TABLE "pharmacies" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "address" VARCHAR(255),
    "contact" VARCHAR(20),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pharmacies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pharmacy_inventories" (
    "id" UUID NOT NULL,
    "pharmacy_id" UUID NOT NULL,
    "medicine_name" VARCHAR(150) NOT NULL,
    "in_stock" BOOLEAN NOT NULL DEFAULT false,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pharmacy_inventories_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pharmacies_user_id_key" ON "pharmacies"("user_id");

-- CreateIndex
CREATE INDEX "pharmacy_inventories_pharmacy_id_idx" ON "pharmacy_inventories"("pharmacy_id");

-- CreateIndex
CREATE INDEX "pharmacy_inventories_medicine_name_idx" ON "pharmacy_inventories"("medicine_name");

-- CreateIndex
CREATE UNIQUE INDEX "users_abha_id_key" ON "users"("abha_id");

-- AddForeignKey
ALTER TABLE "pharmacies" ADD CONSTRAINT "pharmacies_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pharmacy_inventories" ADD CONSTRAINT "pharmacy_inventories_pharmacy_id_fkey" FOREIGN KEY ("pharmacy_id") REFERENCES "pharmacies"("id") ON DELETE CASCADE ON UPDATE CASCADE;
