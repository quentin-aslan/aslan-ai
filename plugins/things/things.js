// JXA backend for server.py: `osascript -l JavaScript things.js '<json request>'` -> JSON on stdout.
// Arguments arrive as JSON (never interpolated into script text): titles come from mails and messages.
const T = Application('Things3');
const LISTS = { inbox: 'Inbox', today: 'Today', upcoming: 'Upcoming', anytime: 'Anytime', someday: 'Someday', logbook: 'Logbook' };
const WAITING_TAG = 'En attente';

function day(iso) { const [y, m, d] = iso.split('-').map(Number); return new Date(y, m - 1, d); }
function iso(date) {
  if (!date) return null;
  const p = n => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${p(date.getMonth() + 1)}-${p(date.getDate())}`;
}
function name(ref) { try { const r = ref(); return r ? r.name() : null; } catch (e) { return null; } }

function serialize(t) {
  const p = t.properties();
  return {
    id: p.id, title: p.name, notes: (p.notes || '').slice(0, 500), status: p.status,
    when: iso(p.activationDate), deadline: iso(p.dueDate), tags: p.tagNames || '',
    project: name(t.project), area: name(t.area),
    completed_ms: p.completionDate ? p.completionDate.getTime() : null,
    modified_ms: p.modificationDate ? p.modificationDate.getTime() : null,
  };
}

function pick(src, keep, limit, extra) {
  const s = { id: src.id(), name: src.name(), notes: src.notes(), status: src.status() };
  const idx = s.id.map((_, i) => i).filter(i => keep(s, i));
  return Object.assign(extra, { count: idx.length, items: idx.slice(0, limit).map(i => serialize(T.toDos.byId(s.id[i]))) });
}

function todo(id) {
  const t = T.toDos.byId(id);
  t.name();  // throws if the id does not exist
  return t;
}

// List moves (today/anytime/someday/inbox) are done by server.py through move.applescript: JXA `move` fails on Things.
function place(t, req) {
  if (req.area) t.area = T.areas.byName(req.area);
  if (req.project) t.project = T.projects.byName(req.project);
  if (/^\d{4}-\d{2}-\d{2}$/.test(req.when || '')) T.schedule(t, { for: day(req.when) });
  if (req.deadline) t.dueDate = day(req.deadline);
}

const actions = {
  list(req) {
    const src = req.list === 'waiting'
      ? T.toDos.whose({ tagNames: { _contains: WAITING_TAG } })
      : T.lists.byName(LISTS[req.list]).toDos;
    return pick(src, (s, i) => req.list === 'logbook' || s.status[i] === 'open', req.limit || 100, { list: req.list });
  },
  search(req) {
    const q = req.query.toLowerCase();
    const seen = new Set();
    let out = [];
    for (const l of ['Inbox', 'Today', 'Upcoming', 'Anytime', 'Someday']) {
      const r = pick(T.lists.byName(l).toDos, (s, i) => {
        if (seen.has(s.id[i])) return false;
        seen.add(s.id[i]);
        return (s.name[i] + '\n' + s.notes[i]).toLowerCase().includes(q);
      }, 50 - out.length, {});
      out = out.concat(r.items);
    }
    return { query: req.query, count: out.length, items: out };
  },
  get_many(req) {
    return req.ids.map(id => { try { return serialize(todo(id)); } catch (e) { return null; } });
  },
  list_one(req) {
    return serialize(todo(req.id));
  },
  count_today() {
    return { count: T.lists.byName('Today').toDos.status().filter(s => s === 'open').length };
  },
  add(req) {
    const t = T.ToDo({ name: req.title, notes: req.notes || '', tagNames: req.tags || '' });
    T.toDos.push(t);
    const created = todo(t.id());
    place(created, req);
    return serialize(created);
  },
  complete(req) {
    const t = todo(req.id);
    t.status = 'completed';
    return serialize(t);
  },
  schedule(req) {
    const t = todo(req.id);
    place(t, req);
    return serialize(t);
  },
  update(req) {
    const t = todo(req.id);
    if (req.title) t.name = req.title;
    if (req.notes != null) t.notes = req.notes;
    if (req.append_notes) t.notes = (t.notes() ? t.notes() + '\n\n' : '') + req.append_notes;
    if (req.tags != null) t.tagNames = req.tags;
    return serialize(t);
  },
};

function run(argv) {
  try {
    const req = JSON.parse(argv[0]);
    if (!actions[req.action]) throw new Error('unknown action ' + req.action);
    return JSON.stringify({ ok: true, result: actions[req.action](req) });
  } catch (e) {
    return JSON.stringify({ ok: false, error: String(e) });
  }
}
