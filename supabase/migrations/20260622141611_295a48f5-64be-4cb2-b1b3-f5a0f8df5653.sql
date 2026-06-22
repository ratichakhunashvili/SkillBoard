
-- 1. Restrict profiles to authenticated users only
DROP POLICY IF EXISTS "profiles readable by all" ON public.profiles;
CREATE POLICY "profiles readable by authenticated"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- 2. Restrict user_achievements leaderboard visibility to authenticated users
DROP POLICY IF EXISTS "all achievements visible for leaderboard" ON public.user_achievements;
CREATE POLICY "achievements visible to authenticated"
ON public.user_achievements FOR SELECT
TO authenticated
USING (true);

-- 3. Hide activities.qr_code from non-admin authenticated users via column-level privileges.
-- Authenticated users can SELECT all other columns; the scan_qr_code() SECURITY DEFINER
-- RPC still validates QR codes server-side without exposing them.
REVOKE SELECT ON public.activities FROM authenticated;
GRANT SELECT (
  id, name, description, event_date, start_time, end_time,
  points, max_scans_per_student, is_active, created_at, created_by
) ON public.activities TO authenticated;
-- Admins need full access including qr_code; grant via service_role and a dedicated admin grant.
GRANT ALL ON public.activities TO service_role;
-- Provide a way for admins to read qr_code: keep RLS admin policy, but column priv must allow it.
-- Grant full SELECT back to the postgres role used by admin RPCs (admin-only access enforced by RLS policy).
-- Since RLS still applies, restoring SELECT to authenticated on qr_code would re-expose it; instead,
-- admin reads of qr_code should go through a SECURITY DEFINER function.
CREATE OR REPLACE FUNCTION public.get_activity_qr(_activity_id uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_qr text;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;
  SELECT qr_code INTO v_qr FROM public.activities WHERE id = _activity_id;
  RETURN v_qr;
END; $$;

-- 4. Lock down SECURITY DEFINER function execution: revoke from PUBLIC/anon.
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, app_role) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.scan_qr_code(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.award_bonus_points(uuid, integer, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_activity_qr(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.scan_qr_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_bonus_points(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_qr(uuid) TO authenticated;
