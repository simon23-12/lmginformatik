# LMG Informatik — Projektnotizen für Claude

Schul-Curriculum-Plattform (Klasse 6, 9, 10) mit Schüler-/Lehrer-Accounts. Statische Seite (kein Build), Backend ist Supabase.

## Stack
- Reines HTML/JS mit ES-Modulen, kein Bundler. Deploy = `git push` (GitHub Pages, später zusätzlich Vercel).
- Supabase: Auth + Postgres + RLS. MCP-Server verbunden (Tools `mcp__supabase__*`) für Migrationen/SQL/Logs.
- Lokal testen: `.claude/launch.json` → `python -m http.server 5500`. ES-Module brauchen `http://`, nicht `file://`.

## Wichtige Regeln
- **Neue Tabellen brauchen immer explizite `GRANT ... TO authenticated`** zusätzlich zur RLS-Policy (Projekt hat "auto-expose new tables" deaktiviert) — sonst 403 trotz korrekter Policy.
- **Nie `/pfad` hartcodieren** für Redirects/Links. Immer `SITE_ROOT` aus [assets/supabase-client.js](assets/supabase-client.js) verwenden (relativ zu `import.meta.url` berechnet) — die Seite läuft sowohl unter GitHub-Pages-Unterpfad (`/lmginformatik/`) als auch später auf Vercel-Root.
- Login läuft über Benutzername, nicht E-Mail: intern wird `{username}@lmg.local` an Supabase Auth durchgereicht.
- Bewertung ist Ampel (`green`/`yellow`/`red` in `submissions.evaluation`), **keine Noten**. Feedback ist beim Bewerten Pflicht.
- `Klasse 6 Buch/` (und künftige `Klasse 9/10 Buch/`) sind urheberrechtlich geschützte Buch-Scans — dauerhaft in `.gitignore`, nie committen.
- `.mcp.json` enthält ein Secret (Supabase Access Token) — bleibt gitignored.
- Repo ist **öffentlich** — bei jeder Änderung kurz prüfen, dass keine Secrets/urheberrechtlichen Inhalte reinrutschen.

## Struktur
- `index.html` — Login/Landingpage
- `dashboard/` — Schüler-Dashboard (Kapitelübersicht + Aufgaben)
- `admin/` — Lehrer-Dashboard (Klassen/Kurse → Fortschritt → bewerten)
- `assets/supabase-client.js` — gemeinsamer Client, Login-/Rollen-/Redirect-Logik
- `supabase_schema.sql` — Referenz-Schema (nicht automatisch ausgeführt, dient als Doku)

Für den vollständigen aktuellen Stand (Seed-Daten, Testzugänge, offene To-dos) siehe [SwitchPC.md](SwitchPC.md).
