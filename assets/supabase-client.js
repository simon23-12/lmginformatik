// Gemeinsamer Supabase-Client für alle Seiten (index, dashboard, admin)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const SUPABASE_URL = 'https://mdwsojyxklocyhiavkex.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_RyYiDj_iyxNQ9RSu2Ma9kw_QpkWXJjk';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Site-Root relativ zu diesem Modul ermitteln, statt "/" hart zu codieren.
// Damit funktionieren die Seiten sowohl auf Vercel (Root-Domain) als auch auf
// GitHub Pages (z.B. https://user.github.io/repo-name/) ohne Anpassung.
export const SITE_ROOT = new URL('..', import.meta.url).href;

// Benutzername -> interne E-Mail (kein echtes Postfach nötig)
export function usernameToEmail(username) {
  return `${username.trim().toLowerCase()}@lmg.local`;
}

export async function loginWithUsername(username, password) {
  return supabase.auth.signInWithPassword({
    email: usernameToEmail(username),
    password
  });
}

// Ermittelt die Rolle des eingeloggten Users ('teacher' | 'student' | null)
export async function getRole(session) {
  const { data: teacher } = await supabase
    .from('teachers')
    .select('id')
    .eq('id', session.user.id)
    .maybeSingle();
  if (teacher) return 'teacher';

  const { data: student } = await supabase
    .from('students')
    .select('id')
    .eq('id', session.user.id)
    .maybeSingle();
  if (student) return 'student';

  return null;
}

// Leitet nach Login zur passenden Rolle weiter
export async function redirectByRole() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return;
  const role = await getRole(session);
  if (role === 'teacher') location.href = new URL('admin/', SITE_ROOT).href;
  else if (role === 'student') location.href = new URL('dashboard/', SITE_ROOT).href;
}

// Schützt eine Seite: leitet zu / zurück, falls keine Session oder falsche Rolle
export async function guardPage(requiredRole) {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) { location.href = SITE_ROOT; return null; }
  const role = await getRole(session);
  if (role !== requiredRole) { location.href = SITE_ROOT; return null; }
  return session;
}
