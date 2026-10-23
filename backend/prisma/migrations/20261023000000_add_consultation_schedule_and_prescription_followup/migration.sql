-- Add structured appointment and treatment metadata without changing existing rows.
ALTER TABLE "consultations"
ADD COLUMN "reason" VARCHAR(200),
ADD COLUMN "scheduled_at" TIMESTAMP(3);

ALTER TABLE "prescriptions"
ADD COLUMN "follow_up_date" TIMESTAMP(3);

CREATE INDEX "consultations_scheduled_at_idx" ON "consultations"("scheduled_at");
