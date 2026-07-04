-- ================================================
-- Feature B: Scheduled Push Notifications
-- ================================================
CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT DEFAULT 'system',
  send_at    TIMESTAMPTZ NOT NULL,
  sent       BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_all_scheduled" ON scheduled_notifications
  FOR ALL USING (true) WITH CHECK (true);

-- ================================================
-- Feature C: Ads click tracking + scheduling
-- ================================================
ALTER TABLE ads ADD COLUMN IF NOT EXISTS clicks    INT  DEFAULT 0;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE ads ADD COLUMN IF NOT EXISTS end_date   DATE;

-- ================================================
-- Feature D: Service Provider Verification Requests
-- ================================================
CREATE TABLE IF NOT EXISTS verification_requests (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status           TEXT DEFAULT 'pending'
                     CHECK (status IN ('pending','approved','rejected')),
  rejection_reason TEXT,
  reviewed_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vr_user   ON verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_vr_status ON verification_requests(status);

ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;

-- Users can see and create their own requests
CREATE POLICY "users_own_vr" ON verification_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_vr" ON verification_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can do everything
CREATE POLICY "admin_all_vr" ON verification_requests
  FOR ALL USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

-- ================================================
-- Pending fixes (notifications type constraint)
-- ================================================
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('system','promotion','ads','service_update','verification','favorite'));

-- ================================================
-- Service Approval System columns (if not done)
-- ================================================
ALTER TABLE services
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved'
    CHECK (status IN ('pending','approved','rejected')),
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_services_status ON services(status);

-- ================================================
-- Onboarding slides table (if not done)
-- ================================================
CREATE TABLE IF NOT EXISTS onboarding_slides (
  id          SERIAL PRIMARY KEY,
  sort_order  INT  DEFAULT 0,
  title_ar    TEXT DEFAULT '',
  title_en    TEXT DEFAULT '',
  subtitle_ar TEXT DEFAULT '',
  subtitle_en TEXT DEFAULT '',
  image_url   TEXT,
  bg_color    TEXT DEFAULT '#B91C4C',
  active      BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE onboarding_slides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_onboarding" ON onboarding_slides
  FOR SELECT USING (true);

CREATE POLICY "admin_all_onboarding" ON onboarding_slides
  FOR ALL USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );
