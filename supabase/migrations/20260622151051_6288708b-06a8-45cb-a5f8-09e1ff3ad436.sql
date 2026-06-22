
CREATE OR REPLACE FUNCTION public.admin_remove_attendance(_attendance_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.attendance%ROWTYPE;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Forbidden');
  END IF;

  SELECT * INTO v_row FROM public.attendance WHERE id = _attendance_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Attendance not found');
  END IF;

  DELETE FROM public.attendance WHERE id = _attendance_id;

  UPDATE public.profiles
  SET total_points = GREATEST(total_points - COALESCE(v_row.points_awarded, 0), 0)
  WHERE id = v_row.student_id;

  RETURN jsonb_build_object('ok', true);
END; $$;

REVOKE EXECUTE ON FUNCTION public.admin_remove_attendance(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_remove_attendance(uuid) TO authenticated;
