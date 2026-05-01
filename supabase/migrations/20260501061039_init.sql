-- KYH 약 알림 v2.0 스키마
-- 부모 anonymous + 자녀 Google/Email + N:M 페어링 + 단방향 미러 + RLS + RPC

-- ─────────────────────────────────────────────
-- 테이블 6개
-- ─────────────────────────────────────────────

-- 부모 디바이스 (anonymous auth user_id)
CREATE TABLE parent_devices (
  id UUID PRIMARY KEY,                  -- = auth.uid()
  device_label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 자녀 사용자 (Google/Email auth user_id)
CREATE TABLE child_users (
  id UUID PRIMARY KEY,                  -- = auth.uid()
  email TEXT,
  display_name TEXT,
  fcm_token TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- N:M 페어링
CREATE TABLE pairings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES child_users(id) ON DELETE CASCADE,
  parent_label TEXT,
  paired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(parent_device_id, child_user_id)
);

-- 페어링 코드 (10분 TTL)
CREATE TABLE pairing_codes (
  code TEXT PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  redeemed_at TIMESTAMPTZ,
  redeemed_by UUID REFERENCES child_users(id)
);

-- 약 미러 (부모 → Supabase 단방향 upsert)
CREATE TABLE medications (
  id UUID PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 복용 이벤트 미러 (부모 → Supabase 단방향 insert)
CREATE TABLE dose_events (
  id UUID PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  slot_id TEXT NOT NULL,
  date DATE NOT NULL,
  status TEXT NOT NULL,                 -- 'taken' | 'missed'
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_dose_events_parent_date ON dose_events(parent_device_id, date);
CREATE INDEX idx_pairings_child ON pairings(child_user_id);
CREATE INDEX idx_pairings_parent ON pairings(parent_device_id);

-- ─────────────────────────────────────────────
-- RLS (Row Level Security)
-- ─────────────────────────────────────────────

ALTER TABLE parent_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_users    ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE dose_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairing_codes  ENABLE ROW LEVEL SECURITY;

-- parent_devices / child_users: 본인만
CREATE POLICY p_parent_self ON parent_devices FOR ALL USING (id = auth.uid());
CREATE POLICY p_child_self  ON child_users    FOR ALL USING (id = auth.uid());

-- pairings: 본인이 한쪽인 페어링만
CREATE POLICY p_pairings_owned ON pairings FOR ALL
  USING (parent_device_id = auth.uid() OR child_user_id = auth.uid());

-- medications: 부모 본인 + 페어링된 자녀(read만)
CREATE POLICY p_meds_read ON medications FOR SELECT
  USING (
    parent_device_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pairings
      WHERE pairings.parent_device_id = medications.parent_device_id
        AND pairings.child_user_id = auth.uid()
    )
  );
CREATE POLICY p_meds_insert ON medications FOR INSERT
  WITH CHECK (parent_device_id = auth.uid());
CREATE POLICY p_meds_update ON medications FOR UPDATE
  USING (parent_device_id = auth.uid());
CREATE POLICY p_meds_delete ON medications FOR DELETE
  USING (parent_device_id = auth.uid());

-- dose_events: 부모 본인 + 페어링된 자녀(read만)
CREATE POLICY p_doses_read ON dose_events FOR SELECT
  USING (
    parent_device_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pairings
      WHERE pairings.parent_device_id = dose_events.parent_device_id
        AND pairings.child_user_id = auth.uid()
    )
  );
CREATE POLICY p_doses_insert ON dose_events FOR INSERT
  WITH CHECK (parent_device_id = auth.uid());

-- pairing_codes: 부모는 자기 코드만 (자녀는 RPC redeem_pairing_code 통해서만)
CREATE POLICY p_codes_parent_own ON pairing_codes FOR ALL
  USING (parent_device_id = auth.uid());

-- ─────────────────────────────────────────────
-- RPC (Stored Functions)
-- ─────────────────────────────────────────────

-- 부모: 6자리 코드 발급 (10분 TTL)
CREATE OR REPLACE FUNCTION create_pairing_code()
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_code TEXT;
BEGIN
  v_code := lpad(floor(random() * 1000000)::text, 6, '0');
  INSERT INTO pairing_codes(code, parent_device_id, expires_at)
    VALUES (v_code, auth.uid(), now() + interval '10 minutes');
  RETURN v_code;
END $$;

-- 자녀: 코드 redeem → pairings에 insert
CREATE OR REPLACE FUNCTION redeem_pairing_code(p_code TEXT, p_label TEXT)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_parent UUID; v_pairing UUID;
BEGIN
  SELECT parent_device_id INTO v_parent
    FROM pairing_codes
    WHERE code = p_code AND expires_at > now() AND redeemed_at IS NULL;
  IF v_parent IS NULL THEN
    RAISE EXCEPTION 'invalid or expired code';
  END IF;
  INSERT INTO pairings(parent_device_id, child_user_id, parent_label)
    VALUES (v_parent, auth.uid(), p_label)
    ON CONFLICT (parent_device_id, child_user_id) DO NOTHING
    RETURNING id INTO v_pairing;
  UPDATE pairing_codes
    SET redeemed_at = now(), redeemed_by = auth.uid()
    WHERE code = p_code;
  RETURN v_pairing;
END $$;
