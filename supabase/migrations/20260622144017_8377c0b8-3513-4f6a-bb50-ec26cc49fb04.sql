
-- 1) SECURITY DEFINER function exposure: revoke from PUBLIC; grant only where needed
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_public_names(uuid[]) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_leaderboard(integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.award_bonus_points(uuid, integer, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_activity_qr(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.scan_qr_code(text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_names(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_bonus_points(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_qr(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.scan_qr_code(text) TO authenticated;

-- 2) Hide activities.qr_code column from non-admins
REVOKE SELECT (qr_code) ON public.activities FROM authenticated, anon, PUBLIC;
-- Ensure regular SELECT on safe columns remains
GRANT SELECT (id, name, description, points, event_date, start_time, end_time, created_at, created_by, is_active, max_scans_per_student)
  ON public.activities TO authenticated;

-- 3) Restrict profiles INSERT/UPDATE to authenticated only
DROP POLICY IF EXISTS "users insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "users update own profile" ON public.profiles;

CREATE POLICY "users insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4) user_roles: explicit per-action admin-only policies, scoped to authenticated
DROP POLICY IF EXISTS "admins manage roles" ON public.user_roles;
DROP POLICY IF EXISTS "admins see all roles" ON public.user_roles;
DROP POLICY IF EXISTS "users see own roles" ON public.user_roles;

CREATE POLICY "users see own roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "admins see all roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "admins insert roles"
  ON public.user_roles FOR INSERT
  TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "admins update roles"
  ON public.user_roles FOR UPDATE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "admins delete roles"
  ON public.user_roles FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
