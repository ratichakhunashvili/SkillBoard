import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/public/seed-demo")({
  server: {
    handlers: {
      POST: async () => {
        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        const email = "ratichakhunashvili@gmail.com";
        const password = "01024072661";
        const fullName = "Admin";
        try {
          const { data: list } = await supabaseAdmin.auth.admin.listUsers();
          let user = list?.users.find((u) => u.email === email);
          if (!user) {
            const { data, error } = await supabaseAdmin.auth.admin.createUser({
              email,
              password,
              email_confirm: true,
              user_metadata: { full_name: fullName },
            });
            if (error) throw error;
            user = data.user!;
          } else {
            await supabaseAdmin.auth.admin.updateUserById(user.id, { password });
          }
          await supabaseAdmin
            .from("user_roles")
            .upsert({ user_id: user.id, role: "admin" }, { onConflict: "user_id,role" });
          return Response.json({ ok: true });
        } catch (err) {
          const message = err instanceof Error ? err.message : "seed failed";
          return Response.json({ ok: false, error: message }, { status: 500 });
        }
      },
    },
  },
});
