
-- Grant per-column SELECT on activities (excluding qr_code) so authenticated users can see activities
GRANT SELECT (id, name, description, event_date, start_time, end_time, points, max_scans_per_student, is_active, created_by, created_at)
  ON public.activities TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.activities TO authenticated;
GRANT ALL ON public.activities TO service_role;
