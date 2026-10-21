CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(150) NOT NULL,

    phone VARCHAR(20) UNIQUE NOT NULL,

    email VARCHAR(255) UNIQUE,

    password_hash TEXT NOT NULL,

    role VARCHAR(20) NOT NULL
        CHECK (role IN ('PATIENT', 'DOCTOR', 'ASHA', 'ADMIN')),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID UNIQUE NOT NULL,

    date_of_birth DATE,

    gender VARCHAR(20),

    village VARCHAR(150),

    district VARCHAR(150),

    state VARCHAR(150),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_patient_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


CREATE TABLE doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID UNIQUE NOT NULL,

    specialization VARCHAR(150),

    registration_number VARCHAR(100) UNIQUE,

    hospital_name VARCHAR(200),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_doctor_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


CREATE TABLE asha_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID UNIQUE NOT NULL,

    village VARCHAR(150),

    district VARCHAR(150),

    state VARCHAR(150),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_asha_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    patient_id UUID NOT NULL,

    doctor_id UUID,

    asha_worker_id UUID,

    type VARCHAR(20) NOT NULL
        CHECK (type IN ('VIDEO', 'AUDIO', 'CHAT', 'OFFLINE')),

    status VARCHAR(20) NOT NULL
        CHECK (status IN ('PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED')),

    symptoms TEXT,

    notes TEXT,

    risk_level VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_consultation_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(id),

    CONSTRAINT fk_consultation_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(id),

    CONSTRAINT fk_consultation_asha
        FOREIGN KEY (asha_worker_id)
        REFERENCES asha_workers(id)
);


CREATE TABLE medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    patient_id UUID NOT NULL,

    consultation_id UUID,

    diagnosis TEXT,

    clinical_notes TEXT,

    ai_analysis JSONB,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_record_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(id),

    CONSTRAINT fk_record_consultation
        FOREIGN KEY (consultation_id)
        REFERENCES consultations(id)
);


CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    patient_id UUID NOT NULL,

    consultation_id UUID,

    doctor_id UUID NOT NULL,

    medicines JSONB NOT NULL,

    instructions TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_prescription_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(id),

    CONSTRAINT fk_prescription_consultation
        FOREIGN KEY (consultation_id)
        REFERENCES consultations(id),

    CONSTRAINT fk_prescription_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(id)
);


CREATE TABLE sync_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    device_id VARCHAR(150) NOT NULL,

    entity_type VARCHAR(100) NOT NULL,

    entity_id UUID,

    operation VARCHAR(20) NOT NULL
        CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),

    status VARCHAR(20) NOT NULL
        CHECK (status IN ('PENDING', 'SYNCED', 'FAILED', 'CONFLICT')),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    synced_at TIMESTAMPTZ
);


CREATE TABLE connectivity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    device_id VARCHAR(150) NOT NULL,

    download_speed DECIMAL(10,2),

    upload_speed DECIMAL(10,2),

    latency_ms INTEGER,

    packet_loss DECIMAL(5,2),

    battery_level INTEGER,

    connectivity_level INTEGER,

    selected_mode VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);