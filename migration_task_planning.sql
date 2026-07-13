-- Migration: Seitenweise Aufgabenplanung mit Schwierigkeitsgrad + Live-Schaltung
-- Ausführen im Supabase SQL Editor (einmalig)
-- Kontext: siehe CLAUDE.md / SwitchPC.md

-- 1. Neue Spalten an tasks
alter table tasks add column if not exists page_number int;
alter table tasks add column if not exists section_title text;
alter table tasks add column if not exists difficulty smallint check (difficulty in (1,2,3)); -- 1=leicht, 2=mittel, 3=schwer
alter table tasks add column if not exists published boolean not null default true; -- default true, damit bestehende Aufgaben sichtbar bleiben

-- 2. Rechte: Lehrer müssen 'published' umschalten können
grant update on tasks to authenticated;

-- 3. RLS neu: Schüler sehen nur freigeschaltete Aufgaben, Lehrer sehen/ändern alles
drop policy if exists "authenticated read tasks" on tasks;

create policy "read tasks" on tasks
  for select to authenticated
  using (
    published = true
    or exists (select 1 from teachers t where t.id = auth.uid())
  );

create policy "teachers update tasks" on tasks
  for update to authenticated
  using (exists (select 1 from teachers t where t.id = auth.uid()))
  with check (exists (select 1 from teachers t where t.id = auth.uid()));

-- 4. Digitalisierte Aufgaben aus "Kapitel 1 - S. 8-27" (Klasse 6 Buch)
-- Neue Aufgaben werden UNPUBLISHED angelegt -- Lehrer schaltet sie im Admin-Bereich
-- passend zur Unterrichtsplanung frei.
do $$
declare
  topic uuid;
begin
  select id into topic from topics where grade = 6 and title = 'Informatik - Was ist das?' limit 1;

  if topic is null then
    raise exception 'Topic "Informatik - Was ist das?" (grade 6) nicht gefunden -- Titel in der DB prüfen und Query anpassen.';
  end if;

  insert into tasks (topic_id, order_index, title, content, task_type, page_number, section_title, difficulty, published) values
  -- Seite 11: Informatik - Ideen und Fachgebiete
  (topic, 100, 'Aufgabe 1', 'a) Warum findest du deine Bücher schneller, wenn du sie nach dem Alphabet sortiert hast? Denke dir ein Beispiel aus.
b) Auch mit Computern, Tablets oder Smartphones kannst du Inhalte (Textdokumente, Bilder, Videos) sortieren. Notiere, wonach du diese Inhalte sortieren (lassen) könntest.', 'text', 11, 'Informatik - Ideen und Fachgebiete', 1, false),
  (topic, 101, 'Aufgabe 2', 'Das Beispiel „Weg zum Zoo" zeigt: Informatikerinnen und Informatiker versuchen, Probleme zu lösen. „Auf welchem Weg komme ich zum Zoo?" ist gelöst. Doch schaue genau: Beim Schritt „Zeichne eine geeignete Strecke auf der Straßenkarte ein" ist unklar, was „geeignet" bedeutet. Schreibe Ideen auf, was eine „geeignete" Strecke ist.', 'text', 11, 'Informatik - Ideen und Fachgebiete', 2, false),
  (topic, 102, 'Aufgabe 3', 'Conrads Schwester kann schon Auto fahren und nimmt Elif und Conrad mit in den Zoo. Zur Navigation nutzt sie eine App auf ihrem Smartphone.
a) Welche Daten muss sie in die App eingeben und welche kann sie eingeben?
b) Wenn du davon ausgehst, dass die App eine detaillierte Straßenkarte (mit Weglängen, Straßenschildern usw.) gespeichert hat: Wie könnte die App den Weg zum Zoo ausrechnen?', 'text', 11, 'Informatik - Ideen und Fachgebiete', 3, false),
  (topic, 103, 'Aufgabe 4', 'Beschreibe die Möglichkeiten, die eintreten können, wenn du bei deiner Freundin anrufst, und was du dann jeweils tun würdest.', 'text', 11, 'Informatik - Ideen und Fachgebiete', 3, false),

  -- Seite 13: Informatiksysteme
  (topic, 110, 'Aufgabe 1', 'Liste auf, wo Informatiksysteme bei dir Zuhause vorkommen.', 'text', 13, 'Informatiksysteme', 1, false),
  (topic, 111, 'Aufgabe 2', 'Ordne Tastatur, Drucker, Scanner, Arbeitsspeicher, Kopfhörer, Mikrofon, Grafikkarte in die Tabelle ein (Spalten: Eingabe / Verarbeitung / Ausgabe; Beispiel: Tastatur -> Eingabe).', 'text', 13, 'Informatiksysteme', 2, false),
  (topic, 112, 'Aufgabe 3', '👥 Partnerarbeit: Diskutiert, ob folgende Geräte Informatiksysteme sein können: Waschmaschine, Kühlschrank, Staubsauger.', 'text', 13, 'Informatiksysteme', 3, false),

  -- Seite 15: Erste Schritte mit einem Informatiksystem
  (topic, 120, 'Aufgabe 1', 'Beschreibe den Anmeldevorgang bei einem Informatiksystem, das du in deiner Schule benutzt. Orientiere dich dabei an dem Automaten in Abb. 1.', 'text', 15, 'Erste Schritte mit einem Informatiksystem', 1, false),
  (topic, 121, 'Aufgabe 2', 'Bei einem Hotelzimmer kannst du die Zimmertür mithilfe einer elektronischen Karte öffnen. Zeichne den Automaten zu dieser Situation in Anlehnung an Abb. 1.', 'text', 15, 'Erste Schritte mit einem Informatiksystem', 1, false),
  (topic, 122, 'Aufgabe 3', '👥 Gruppenarbeit: Sammelt in einem Online-Texteditor eurer Wahl, welche Bestandteile ihr für einen Startbildschirm sinnvoll erscheinen.', 'text', 15, 'Erste Schritte mit einem Informatiksystem', 2, false),

  -- Seite 17: Der Verzeichnisbaum - Struktur für Daten
  (topic, 130, 'Aufgabe 1', 'Conrad hat sich folgende Verzeichnisse für seine Musikdateien überlegt: Klassik, Rock, Rap, Modern, Orchester, Chor, RapperX, RapperY, Chor1, Chor2, RockBand1, RockBand2. Ordne die gegebenen Verzeichnisse sinnvoll in einem Verzeichnisbaum mit mehreren Ebenen an.', 'text', 17, 'Der Verzeichnisbaum - Struktur für Daten', 1, false),
  (topic, 131, 'Aufgabe 2', 'Erstelle eine sinnvolle Verzeichnisstruktur für deinen Arbeitsbereich auf dem Informatiksystem deiner Schule.
a) Berücksichtige die verschiedenen Fächer und überlege, welche weiteren Unterteilungen Sinn machen.
b) Stelle deine Struktur auf zwei Weisen dar (→ Abb. 5).
c) Erstelle die Verzeichnisstruktur auf deinem Arbeitsbereich des Informatiksystems deiner Schule.', 'text', 17, 'Der Verzeichnisbaum - Struktur für Daten', 1, false),
  (topic, 132, 'Aufgabe 3', 'Bisher hast du meistens gleiche „Dateitypen" in einem Verzeichnis zusammengefasst (z. B. waren in deinen Alben immer Fotodateien oder bei Aufgabe 1 sind Musikdateien in den Verzeichnissen abgelegt).
a) Nenne andere dir bekannte Dateitypen.
b) Notiere für die einzelnen Verzeichnisse aus Aufgabe 2, welche Dateitypen du in den jeweiligen Verzeichnissen erwarten würdest.', 'text', 17, 'Der Verzeichnisbaum - Struktur für Daten', 2, false),

  -- Seite 19: Informatische Modellierung - zentrale Arbeitsweise der Informatik
  (topic, 140, 'Aufgabe 1', 'Conrad hat seine Anziehsachen nach Wetterlage sortiert. Überlege, wonach er sie noch sortieren könnte.', 'text', 19, 'Informatische Modellierung - zentrale Arbeitsweise der Informatik', 1, false),
  (topic, 141, 'Aufgabe 2', 'Der gesamte Inhalt deiner Schultasche liegt völlig durcheinander auf deinem Schreibtisch.
a) Notiere dir, auf welche Weise du die Sachen auf dem Schreibtisch sortieren möchtest.
b) Nun sortierst du die Sachen so, wie du es dir vorher überlegt hast.
c) Bist du mit dem Ergebnis zufrieden? Begründe deine Antwort.', 'text', 19, 'Informatische Modellierung - zentrale Arbeitsweise der Informatik', 2, false),
  (topic, 142, 'Aufgabe 3', 'Stelle dir vor, du kommst mitten in der Pause an den Schulkiosk. Es ist sehr voll.
a) Beschreibe genau, wie die Menschen vor dem Kiosk stehen und wann sie wieder weggehen.
b) Beschreibe, was passiert, bis du am Kiosk etwas kaufen kannst.
c) 👥 Gruppenarbeit: Stellt die Situation nach und spielt den Ablauf durch.', 'text', 19, 'Informatische Modellierung - zentrale Arbeitsweise der Informatik', 3, false),
  (topic, 143, 'Aufgabe 4', 'Beschreibe mithilfe der Begriffe im Wortspeicher, wie der informatische Modellierungskreis funktioniert.
Wortspeicher: Problem - Lösung - Situation - Modell - Konsequenzen - Ergebnisse', 'text', 19, 'Informatische Modellierung - zentrale Arbeitsweise der Informatik', 3, false),

  -- Seite 21 (Vertiefung): Informatik in meinem Zimmer
  (topic, 150, 'Aufgabe 1', 'Ergänze die Objektkarte zu Conrads Teddybär um zwei Attribute, die (neben dem Standort) im obigen Text erwähnt werden.', 'text', 21, 'Informatik in meinem Zimmer (Vertiefung)', 1, false),
  (topic, 151, 'Aufgabe 2', 'Erstelle drei Objektkarten zu Spielsachen, mit denen du früher gespielt hast. Überlege dir dazu je zwei geeignete Attribute und Methoden.', 'text', 21, 'Informatik in meinem Zimmer (Vertiefung)', 2, false),
  (topic, 152, 'Aufgabe 3', '👥 Modelliert eine Datei auf einem Informatiksystem eurer Wahl objektorientiert. Hinweis: Schaut euch an, was ihr mit der Datei alles tun könnt (Methoden) und welche Eigenschaften sie hat (Attribute).', 'text', 21, 'Informatik in meinem Zimmer (Vertiefung)', 3, false),

  -- Seite 23 (Vertiefung): Was ist Automatik?
  (topic, 160, 'Aufgabe 1a)', '👥 Gruppenarbeit: Bearbeitet gemeinsam das Projekt „Automaten in deinem Alltag" (→ S. 22).', 'text', 23, 'Was ist Automatik? (Vertiefung)', 1, false),
  (topic, 161, 'Aufgabe 1b)-1c)', '👥 b) Beschreibt für einen eurer Automaten die Funktionsweise genauer. Gelingt es euch auch, einen Zustandsgraphen zu zeichnen?
c) Automaten erhalten klare Eingaben und reagieren durch Zustandswechsel. Habt ihr auch Dinge gefunden, die demnach gar keine „informatischen" Automaten sind?', 'text', 23, 'Was ist Automatik? (Vertiefung)', 3, false),
  (topic, 162, 'Aufgabe 2', 'Erkläre mithilfe der Begriffe im Wortspeicher und anhand des Lampen-Beispiels (→ S. 22), wie ein Automat funktioniert.
Wortspeicher: Automat - Fernbedienung - Eingabe („I" und „O") - Zustand („An" und „Aus")', 'text', 23, 'Was ist Automatik? (Vertiefung)', 2, false),
  (topic, 163, 'Aufgabe 3', 'Betrachte den Automaten (→ Abb. 5):
a) Gib alle Zeichen an, um von „Aus" zu „Dunkel" zu „Aus" zu kommen.
b) Gib den Zustand an, den du von „Aus" nach „I, -, +, +" erreichst.
c) Gib die Zeichen an, um vom Start nach „Mittel" zu gelangen.', 'text', 23, 'Was ist Automatik? (Vertiefung)', 2, false),
  (topic, 164, 'Aufgabe 4', 'Elif kauft eine Lichterkette, die beim Drücken von „I" zwischen rot, grün und blau wechselt. Bei „O" schaltet sie immer aus.
a) Beschreibe alle Zustände dieses Automaten.
b) Zeichne den Zustandsgraphen.', 'text', 23, 'Was ist Automatik? (Vertiefung)', 3, false),

  -- Seite 25 (Vertiefung): Netzwerke - der Weg einer Nachricht durch das Internet
  (topic, 170, 'Aufgabe 1', 'Finde heraus, welche „Arten von Daten" du über einen modernen Messenger als Nachricht versenden kannst. Nenne mindestens vier Arten.', 'text', 25, 'Netzwerke - der Weg einer Nachricht durch das Internet (Vertiefung)', 1, false),
  (topic, 171, 'Aufgabe 2', 'Recherchiere, wofür das Internet am Anfang eigentlich erfunden wurde.', 'text', 25, 'Netzwerke - der Weg einer Nachricht durch das Internet (Vertiefung)', 2, false),
  (topic, 172, 'Aufgabe 3', 'Auf dem Weg von Elifs zu Conrads Smartphone wandern die Daten über viele Informatiksysteme. Mindestens eines davon gehört dem Anbieter der Messenger-App, über die Elif und Conrad chatten. Beschreibe, was dieses Informatiksystem für eine besondere Aufgabe hat, damit Elifs und Conrads Smartphones miteinander „sprechen" können.', 'text', 25, 'Netzwerke - der Weg einer Nachricht durch das Internet (Vertiefung)', 3, false),
  (topic, 173, 'Aufgabe 4', 'Recherchiere, was das „transatlantische Telefonkabel" ist.', 'text', 25, 'Netzwerke - der Weg einer Nachricht durch das Internet (Vertiefung)', 1, false),

  -- Seite 27 (Extra): Berühmte Menschen aus der Informatik
  (topic, 180, 'Aufgabe 1 (a-d)', '👥 Gruppenarbeit: Gestaltet mithilfe eines Online-Mindmapping-Tools eurer Wahl Profile zu untenstehenden Personen. Orientiert euch dabei an der Gestaltung in Abb. 1.
a) Gottfried Wilhelm Leibniz
b) Charles Babbage
c) Herman Hollerith
d) Konrad Zuse', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 1, false),
  (topic, 181, 'Aufgabe 1 (e-j)', '👥 Fortsetzung von Aufgabe 1 - Profile zu:
e) Linus Torvalds
f) Joseph Weizenbaum
g) Douglas C. Engelbart
h) Katherine Johnson
i) Richard Stallman
j) Tim Berners Lee', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 2, false),
  (topic, 182, 'Aufgabe 1 (k-m)', '👥 Fortsetzung von Aufgabe 1 - Profile zu:
k) Edsger W. Dijkstra
l) Christiane Floyd
m) Donald E. Knuth', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 3, false),
  (topic, 183, 'Aufgabe 2', '👥 Gruppenarbeit: Findet heraus, was die Fotos auf den Profilen in Abb. 1 zu bedeuten haben. Sammelt eure Ergebnisse in einem Online-Texteditor eurer Wahl.', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 2, false),
  (topic, 184, 'Aufgabe 3', 'Stelle dir vor, du könntest eine Person aus der Informatik treffen und ihr Fragen stellen. Wen würdest du treffen wollen und was für Fragen würdest du ihr oder ihm stellen? Begründe deine Antwort.', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 1, false),
  (topic, 185, 'Aufgabe 4', '👥 Gruppenarbeit: Diskutiert über die Zitate in den vier Profilen (→ S. 26). Erklärt den Sinn der Aussagen in eigenen Worten.', 'text', 27, 'Berühmte Menschen aus der Informatik (Extra)', 3, false);

end $$;
