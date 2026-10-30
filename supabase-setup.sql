-- ==============================================================================
-- Thynkculture Client Portal & Admin Setup
-- Run this in your Supabase Project -> SQL Editor
-- ==============================================================================

-- 1. Enable pgcrypto extension for secure bcrypt password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Create client_accounts table to store login credentials
CREATE TABLE IF NOT EXISTS client_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL UNIQUE REFERENCES clients(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Case-insensitive unique username index
CREATE UNIQUE INDEX IF NOT EXISTS idx_client_accounts_username 
ON client_accounts (LOWER(username));

-- 3. Function for client login (called by client.thynkculture.com)
CREATE OR REPLACE FUNCTION client_login(p_username TEXT, p_password TEXT)
RETURNS JSONB 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public
AS $$
DECLARE
  v_account RECORD;
  v_client RECORD;
  v_posts JSONB;
BEGIN
  -- Verify username & bcrypt password hash
  SELECT * INTO v_account
  FROM client_accounts
  WHERE LOWER(username) = LOWER(TRIM(p_username))
    AND password_hash = crypt(p_password, password_hash);

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid username or password.');
  END IF;

  -- Get client details
  SELECT id, name, slug, accent_color INTO v_client
  FROM clients WHERE id = v_account.client_id;

  -- Get client posts
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'date', post_date,
        'type', type,
        'pillar', pillar,
        'content', content,
        'ref_link', ref_link,
        'status', status,
        'image_url', image_url
      ) ORDER BY post_date
    ),
    '[]'::jsonb
  ) INTO v_posts
  FROM posts WHERE client_id = v_account.client_id;

  RETURN jsonb_build_object(
    'success', true,
    'client', jsonb_build_object(
      'id', v_client.id,
      'name', v_client.name,
      'slug', v_client.slug,
      'username', v_account.username,
      'accent_color', v_client.accent_color
    ),
    'posts', v_posts
  );
END;
$$;

-- 4. Function for admin to set or reset client login credentials
CREATE OR REPLACE FUNCTION admin_set_client_login(
  p_client_id UUID,
  p_username TEXT,
  p_password TEXT
)
RETURNS JSONB 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public
AS $$
BEGIN
  -- Ensure caller is an authenticated team member (admin)
  IF NOT EXISTS (SELECT 1 FROM team_members WHERE user_id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required.');
  END IF;

  IF p_username IS NULL OR LENGTH(TRIM(p_username)) < 2 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Username must be at least 2 characters.');
  END IF;

  IF p_password IS NULL OR LENGTH(p_password) < 4 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Password must be at least 4 characters.');
  END IF;

  INSERT INTO client_accounts (client_id, username, password_hash, updated_at)
  VALUES (p_client_id, TRIM(p_username), crypt(p_password, gen_salt('bf')), now())
  ON CONFLICT (client_id) DO UPDATE SET
    username = EXCLUDED.username,
    password_hash = EXCLUDED.password_hash,
    updated_at = now();

  RETURN jsonb_build_object('success', true);
EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', false, 'error', 'Username is already taken by another client.');
END;
$$;

-- 5. Add canvas column to clients for documents, links, pillars, and markdown notes
ALTER TABLE clients ADD COLUMN IF NOT EXISTS canvas JSONB DEFAULT '{}'::jsonb;

-- 6. Add logo_url column to clients for square logo avatar
ALTER TABLE clients ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- 7. Add details column to clients for contact details, duration, and engagement notes
ALTER TABLE clients ADD COLUMN IF NOT EXISTS details JSONB DEFAULT '{}'::jsonb;


