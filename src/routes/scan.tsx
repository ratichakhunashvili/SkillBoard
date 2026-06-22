import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/use-auth";
import { Loader } from "@/components/loader";
import { CheckCircle2, XCircle } from "lucide-react";
import { toast } from "sonner";

type ScanSearch = { code?: string };

export const Route = createFileRoute("/scan")({
  validateSearch: (s: Record<string, unknown>): ScanSearch => ({
    code: typeof s.code === "string" ? s.code : undefined,
  }),
  head: () => ({ meta: [{ title: "Scan — SkillBoard" }] }),
  component: ScanRedirectPage,
});

function ScanRedirectPage() {
  const { code } = Route.useSearch();
  const { user, role, loading } = useAuth();
  const navigate = useNavigate();
  const ran = useRef(false);
  const [state, setState] = useState<
    | { kind: "idle" }
    | { kind: "scanning" }
    | { kind: "ok"; points: number; activity: string }
    | { kind: "error"; message: string }
  >({ kind: "idle" });

  // No code → go home
  useEffect(() => {
    if (!code) navigate({ to: "/" });
  }, [code, navigate]);

  // Not authenticated → save code and send to /auth with redirect-back
  useEffect(() => {
    if (loading || !code) return;
    if (!user) {
      try {
        sessionStorage.setItem("pending_scan_code", code);
      } catch {
        /* ignore */
      }
      navigate({
        to: "/auth",
        search: { next: `/scan?code=${encodeURIComponent(code)}` } as never,
      });
    }
  }, [user, loading, code, navigate]);

  // Authenticated → run the scan once
  useEffect(() => {
    if (loading || !user || !code || ran.current) return;
    ran.current = true;
    setState({ kind: "scanning" });

    (async () => {
      const { data, error } = await supabase.rpc("scan_qr_code", { _qr: code });
      if (error) {
        setState({ kind: "error", message: error.message });
        return;
      }
      const res = data as { ok: boolean; error?: string; points?: number; activity?: string };
      if (!res.ok) {
        setState({ kind: "error", message: res.error ?? "Scan failed" });
        return;
      }
      try {
        sessionStorage.removeItem("pending_scan_code");
      } catch {
        /* ignore */
      }
      toast.success(`+${res.points} pts · ${res.activity}`);
      setState({
        kind: "ok",
        points: res.points ?? 0,
        activity: res.activity ?? "Activity",
      });
    })();
  }, [user, loading, code]);

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-sm glass rounded-3xl p-8 text-center">
        {state.kind === "ok" ? (
          <>
            <CheckCircle2 className="h-12 w-12 text-primary mx-auto mb-3" />
            <div className="text-lg font-semibold">{state.activity}</div>
            <div className="text-3xl font-bold text-gradient mt-2">+{state.points} pts</div>
            <button
              onClick={() =>
                navigate({ to: role === "admin" ? "/admin" : "/app" })
              }
              className="mt-6 w-full bg-primary text-primary-foreground rounded-xl py-2.5 font-medium glow"
            >
              Continue
            </button>
          </>
        ) : state.kind === "error" ? (
          <>
            <XCircle className="h-12 w-12 text-destructive mx-auto mb-3" />
            <div className="text-base font-medium">{state.message}</div>
            <button
              onClick={() => navigate({ to: role === "admin" ? "/admin" : "/app" })}
              className="mt-6 w-full glass rounded-xl py-2.5 text-sm hover:bg-white/10"
            >
              Back to app
            </button>
          </>
        ) : (
          <>
            <Loader />
            <p className="text-sm text-muted-foreground mt-3">
              {loading || !user ? "Checking your account…" : "Recording your attendance…"}
            </p>
          </>
        )}
      </div>
    </div>
  );
}
