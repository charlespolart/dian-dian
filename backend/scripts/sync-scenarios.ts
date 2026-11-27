/**
 * The two-phone cases of the offline sync (chantier 10, spec
 * docs/superpowers/specs/2026-11-26-offline-sync-design.md, H17 to H29),
 * end to end against a RUNNING backend (default http://localhost:3001).
 *
 * Each "phone" below keeps a copy and a queue by the rules of the app's
 * copy (flutter_app/lib/data/local_store.dart and sync_engine.dart): the
 * numbers a change carries, the merge of changes to one element, the read
 * of what changed before sending what waited, the recolour of what waits.
 * App 1.4.0 is simulated by the routes it uses today. Every scenario checks
 * what the spec says, then that both phones end with the server's copy.
 *
 * Registers two throwaway accounts and deletes them at the end.
 * Run: cd backend && npx tsx scripts/sync-scenarios.ts
 */
import 'dotenv/config';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const BASE = process.env.SMOKE_BASE ?? 'http://localhost:3001';
const password = 'scenario-password-123';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Json = any;

async function http(method: string, path: string, token: string | null, body?: unknown): Promise<{ status: number; json: Json }> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json: Json = null;
  try { json = JSON.parse(text); } catch { /* non-JSON body */ }
  return { status: res.status, json };
}

async function register(email: string): Promise<string> {
  const r = await http('POST', '/api/auth/register', null, { email, password });
  assert.equal(r.status, 201, `register: ${JSON.stringify(r.json)}`);
  return r.json.accessToken as string;
}

async function login(email: string): Promise<string> {
  const r = await http('POST', '/api/auth/login', null, { email, password });
  assert.equal(r.status, 200, `login: ${JSON.stringify(r.json)}`);
  return r.json.accessToken as string;
}

const two = (n: number) => String(n).padStart(2, '0');
const cellKey = (pageId: string, y: number, m: number, d: number) => `${pageId}:${y}-${two(m)}-${two(d)}`;

interface Page { title: string; position: number; palette: Json; keepFree: boolean; editRev: number; contentRev: number; legendsOrderRev: number }
interface Legend { pageId: string; color: string; label: string; position: number; editRev: number }
interface Cell { color: string | null; comment: string | null; editRev: number }
interface Queued { id: string; kind: string; element: string; pageId: string | null; base: number | null; data: Json; waited: boolean; sent: boolean }

/** A phone: its copy of the account, its queue, what it was told. */
class Phone {
  offline = false;
  rev = 0;
  needsFull = true;
  pages = new Map<string, Page>();
  legends = new Map<string, Legend>();
  cells = new Map<string, Cell>();
  settings = new Map<string, { value: Json; rev: number }>();
  pagesOrderRev = 0;
  keepFreeRev = 0;
  queue: Queued[] = [];
  outcomes: Json[] = [];

  constructor(readonly name: string, readonly token: string) {}

  // --- writing on the phone ------------------------------------------------

  /** A gesture: written on the phone with its entry in the queue; sent at once online. */
  async change(kind: string, data: Json): Promise<Queued> {
    const q = this.record(kind, data);
    if (!this.offline) await this.sync();
    return q;
  }

  record(kind: string, data: Json): Queued {
    const element = this.elementOf(kind, data);
    const pageId = kind.startsWith('cell.') || kind === 'legend.create' || kind === 'legends.reorder'
      ? data.pageId as string
      : kind.startsWith('page.') ? data.id as string
      : kind === 'legend.update' || kind === 'legend.delete' ? this.legends.get(data.id)?.pageId ?? null : null;
    const base = this.baseOf(kind, data);
    this.applyLocal(kind, data);
    const last = [...this.queue].reverse().find((q) => q.element === element && !q.sent);
    if (last && Phone.merges(last.kind, kind)) {
      last.data = kind.endsWith('.update') ? { ...last.data, ...data } : data;
      last.kind = kind;
      last.waited = last.waited || this.offline;
      return last; // the first base stays (H28)
    }
    const q: Queued = { id: randomUUID(), kind, element, pageId, base, data, waited: this.offline, sent: false };
    this.queue.push(q);
    return q;
  }

  static merges(earlier: string, later: string): boolean {
    const days = new Set(['cell.set', 'cell.clear']);
    if (days.has(earlier) && days.has(later)) return true;
    if (earlier !== later) return false;
    return !['page.create', 'legend.create', 'page.delete', 'legend.delete'].includes(later);
  }

  elementOf(kind: string, d: Json): string {
    if (kind.startsWith('cell.')) return `cell:${cellKey(d.pageId, d.year, d.month, d.day)}`;
    if (kind === 'page.delete') return `page-delete:${d.id}`;
    if (kind.startsWith('page.')) return `page:${d.id}`;
    if (kind === 'pages.reorder') return 'pages-order';
    if (kind === 'pages.keep') return 'pages-keep';
    if (kind.startsWith('legend.')) return `legend:${d.id}`;
    if (kind === 'legends.reorder') return `legends-order:${d.pageId}`;
    if (kind === 'setting.set') return `setting:${d.key}`;
    throw new Error(`unknown kind ${kind}`);
  }

  baseOf(kind: string, d: Json): number | null {
    switch (kind) {
      case 'cell.set': case 'cell.clear': return this.cells.get(cellKey(d.pageId, d.year, d.month, d.day))?.editRev ?? 0;
      case 'page.update': return this.pages.get(d.id)?.editRev ?? null;
      case 'page.delete': return this.pages.get(d.id)?.contentRev ?? null;
      case 'pages.reorder': return this.pagesOrderRev;
      case 'pages.keep': return this.keepFreeRev;
      case 'legend.update': case 'legend.delete': return this.legends.get(d.id)?.editRev ?? null;
      case 'legends.reorder': return this.pages.get(d.pageId)?.legendsOrderRev ?? null;
      case 'setting.set': return this.settings.get(d.key)?.rev ?? 0;
      default: return null; // creations
    }
  }

  applyLocal(kind: string, d: Json) {
    switch (kind) {
      case 'cell.set': {
        const key = cellKey(d.pageId, d.year, d.month, d.day);
        this.cells.set(key, { color: d.color, comment: d.comment ?? null, editRev: this.cells.get(key)?.editRev ?? 0 });
        break;
      }
      case 'cell.clear': {
        const cell = this.cells.get(cellKey(d.pageId, d.year, d.month, d.day));
        if (cell) { cell.color = null; cell.comment = null; }
        break;
      }
      case 'page.create':
        this.pages.set(d.id, { title: d.title, position: this.pages.size, palette: d.palette ?? null, keepFree: false, editRev: 0, contentRev: 0, legendsOrderRev: 0 });
        for (const [i, l] of (d.legends ?? []).entries()) this.legends.set(l.id, { pageId: d.id, color: l.color, label: l.label, position: i, editRev: 0 });
        break;
      case 'page.update': {
        const p = this.pages.get(d.id);
        if (p && d.title !== undefined) p.title = d.title;
        if (p && d.palette !== undefined) p.palette = d.palette;
        break;
      }
      case 'page.delete': this.dropPage(d.id); break;
      case 'pages.reorder': this.order(this.pages, d.ids); break;
      case 'pages.keep': for (const [id, p] of this.pages) p.keepFree = d.ids.includes(id); break;
      case 'legend.create': this.legends.set(d.id, { pageId: d.pageId, color: d.color, label: d.label, position: this.legendsOf(d.pageId).length, editRev: 0 }); break;
      case 'legend.update': {
        const l = this.legends.get(d.id);
        if (!l) break;
        if (d.color !== undefined && d.color !== l.color) this.recolorDays(l.pageId, l.color, d.color);
        if (d.label !== undefined) l.label = d.label;
        if (d.color !== undefined) l.color = d.color;
        break;
      }
      case 'legend.delete': this.legends.delete(d.id); break;
      case 'legends.reorder': this.order(new Map(this.legendsOf(d.pageId)), d.ids); break;
      case 'setting.set': this.settings.set(d.key, { value: d.value, rev: this.settings.get(d.key)?.rev ?? 0 }); break;
    }
  }

  legendsOf(pageId: string): [string, Legend][] {
    return [...this.legends].filter(([, l]) => l.pageId === pageId).sort((a, b) => a[1].position - b[1].position);
  }

  order<T extends { position: number }>(items: Map<string, T>, ids: string[]) {
    let i = 0;
    for (const id of ids) { const x = items.get(id); if (x) x.position = i++; }
    for (const [id, x] of [...items].sort((a, b) => a[1].position - b[1].position)) if (!ids.includes(id)) x.position = i++;
  }

  dropPage(id: string) {
    this.pages.delete(id);
    for (const [lid, l] of this.legends) if (l.pageId === id) this.legends.delete(lid);
    for (const key of this.cells.keys()) if (key.startsWith(`${id}:`)) this.cells.delete(key);
  }

  recolorDays(pageId: string, from: string, to: string) {
    for (const [key, c] of this.cells) if (key.startsWith(`${pageId}:`) && c.color === from) c.color = to;
  }

  // --- syncing -------------------------------------------------------------

  /** Offline: what is queued has waited. Online: read first if something
   * waited (H29), send the queue in order, read what changed. [loseAnswer]:
   * the server applies the first batch but its answer never arrives. */
  async sync({ loseAnswer = false } = {}) {
    if (this.offline) {
      for (const q of this.queue) q.waited = true;
      return;
    }
    if (this.queue.some((q) => q.waited && !q.sent)) await this.pull();
    while (this.queue.length > 0) {
      // A batch stops before a second change of one element: it leaves once
      // the first one's answer has given it its number (H28).
      const seen = new Set<string>();
      const batch: Queued[] = [];
      for (const q of this.queue.slice(0, 100)) {
        if (seen.has(q.element)) break;
        seen.add(q.element);
        batch.push(q);
      }
      for (const q of batch) q.sent = true;
      const res = await http('POST', '/api/sync/mutations', this.token, {
        mutations: batch.map((q) => ({ id: q.id, kind: q.kind, waited: q.waited, base: q.base, data: q.data })),
      });
      assert.equal(res.status, 200, `${this.name} send: ${JSON.stringify(res.json)}`);
      if (loseAnswer) {
        // As the engine does on a failed send: everything still queued has waited.
        for (const q of this.queue) q.waited = true;
        return;
      }
      this.settle(res.json.results);
    }
    await this.pull();
  }

  settle(results: Json[]) {
    for (const r of results) {
      const i = this.queue.findIndex((q) => q.id === r.id);
      if (i < 0) continue;
      const m = this.queue[i];
      this.queue.splice(i, 1);
      if (r.status === 'applied') {
        const element = r.revs?.element as number | undefined;
        const content = r.revs?.content as number | undefined;
        if (element !== undefined) {
          for (const q of this.queue.slice(i)) if (q.element === m.element) q.base = element;
          this.setNumber(m, element);
        }
        if (content !== undefined && m.pageId) {
          for (const q of this.queue.slice(i)) if (q.kind === 'page.delete' && q.pageId === m.pageId) q.base = content;
          const p = this.pages.get(m.pageId);
          if (p) p.contentRev = content;
        }
        continue;
      }
      this.outcomes.push({ kind: m.kind, data: m.data, status: r.status, current: r.current, reason: r.reason });
      this.needsFull = true; // set aside or refused: the full copy puts the phone right
      if (r.status === 'rejected') continue;
      const legendOnly = m.kind === 'legend.update' || m.kind === 'legend.delete';
      if (r.status === 'deleted' && m.pageId && !legendOnly) {
        const later = this.queue.slice(i).filter((q) => q.pageId === m.pageId);
        for (const d of later) this.outcomes.push({ kind: d.kind, data: d.data, status: 'deleted' });
        this.queue = this.queue.filter((q) => !later.includes(q));
      }
    }
  }

  setNumber(m: Queued, rev: number) {
    const d = m.data;
    switch (m.kind) {
      case 'cell.set': case 'cell.clear': { const c = this.cells.get(cellKey(d.pageId, d.year, d.month, d.day)); if (c) c.editRev = rev; break; }
      case 'page.create': case 'page.update': { const p = this.pages.get(d.id); if (p) p.editRev = rev; break; }
      case 'legend.create': case 'legend.update': { const l = this.legends.get(d.id); if (l) l.editRev = rev; break; }
      case 'pages.reorder': this.pagesOrderRev = rev; break;
      case 'pages.keep': this.keepFreeRev = rev; break;
      case 'legends.reorder': { const p = this.pages.get(d.pageId); if (p) p.legendsOrderRev = rev; break; }
      case 'setting.set': { const s = this.settings.get(d.key); if (s) s.rev = rev; break; }
    }
  }

  async pull() {
    const res = await http('GET', `/api/sync?since=${this.needsFull ? 0 : this.rev}`, this.token);
    assert.equal(res.status, 200, `${this.name} pull: ${JSON.stringify(res.json)}`);
    this.applyServer(res.json);
  }

  applyServer(d: Json) {
    const waiting = new Set(this.queue.map((q) => q.element));
    const deleting = new Set(this.queue.filter((q) => q.kind === 'page.delete').map((q) => q.pageId));
    const creating = new Set(this.queue.filter((q) => q.kind === 'page.create').map((q) => q.pageId));
    const creatingLegends = new Set(this.queue.filter((q) => q.kind === 'legend.create').map((q) => q.data.id));
    if (d.full) {
      const serverPages = new Set(d.pages.map((p: Json) => p.id));
      for (const id of [...this.pages.keys()]) if (!serverPages.has(id) && !creating.has(id)) this.dropPage(id);
      const serverLegends = new Set(d.legends.map((l: Json) => l.id));
      for (const id of [...this.legends.keys()]) if (!serverLegends.has(id) && !creatingLegends.has(id) && !waiting.has(`legend:${id}`)) this.legends.delete(id);
      const serverCells = new Set(Object.entries(d.cells as Record<string, Json[]>).flatMap(([pageId, rows]) => rows.map((c) => cellKey(pageId, c[0], c[1], c[2]))));
      for (const key of [...this.cells.keys()]) {
        if (!serverCells.has(key) && !waiting.has(`cell:${key}`) && !creating.has(key.split(':')[0])) this.cells.delete(key);
      }
    }
    for (const p of d.pages) {
      if (deleting.has(p.id)) continue;
      const mine = waiting.has(`page:${p.id}`);
      const local = this.pages.get(p.id);
      const next: Page = local ?? { title: p.title, position: p.position, palette: p.palette, keepFree: false, editRev: p.editRev, contentRev: 0, legendsOrderRev: 0 };
      if (!mine) { next.title = p.title; next.palette = p.palette; next.editRev = p.editRev; }
      if (!waiting.has('pages-order') || !local) next.position = p.position;
      if (!waiting.has('pages-keep')) next.keepFree = p.keepFree === true;
      next.contentRev = p.contentRev;
      next.legendsOrderRev = p.legendsOrderRev;
      this.pages.set(p.id, next);
    }
    for (const l of d.legends) {
      if (deleting.has(l.pageId) || waiting.has(`legend:${l.id}`)) continue;
      const local = this.legends.get(l.id);
      // A legend recoloured elsewhere recolours what waits (H29).
      if (local && local.color !== l.color) {
        this.recolorDays(l.pageId, local.color, l.color);
        for (const q of this.queue) if (q.kind === 'cell.set' && q.pageId === l.pageId && !q.sent && q.data.color === local.color) q.data = { ...q.data, color: l.color };
      }
      this.legends.set(l.id, {
        pageId: l.pageId, color: l.color, label: l.label, editRev: l.editRev,
        position: waiting.has(`legends-order:${l.pageId}`) && local ? local.position : l.position,
      });
    }
    for (const [pageId, rows] of Object.entries(d.cells as Record<string, Json[]>)) {
      if (deleting.has(pageId)) continue;
      for (const c of rows) {
        const key = cellKey(pageId, c[0], c[1], c[2]);
        if (waiting.has(`cell:${key}`)) continue;
        this.cells.set(key, { color: c[3], comment: c[4], editRev: c[6] });
      }
    }
    for (const t of d.deletions) {
      if (t.kind === 'page' && !creating.has(t.key)) this.dropPage(t.key);
      if (t.kind === 'legend' && !waiting.has(`legend:${t.key}`)) this.legends.delete(t.key);
      if (t.kind === 'cell' && !waiting.has(`cell:${t.key}`)) this.cells.set(t.key, { color: null, comment: null, editRev: t.rev });
    }
    if (d.pagesOrder && !waiting.has('pages-order')) { this.order(this.pages, d.pagesOrder.ids); this.pagesOrderRev = d.pagesOrder.rev; }
    if (d.keepFree && !waiting.has('pages-keep')) {
      for (const [id, p] of this.pages) p.keepFree = d.keepFree.ids.includes(id);
      this.keepFreeRev = d.keepFree.rev;
    }
    for (const [pageId, o] of Object.entries(d.legendsOrder as Record<string, Json>)) {
      if (!waiting.has(`legends-order:${pageId}`)) {
        this.order(new Map(this.legendsOf(pageId)), o.ids);
        const p = this.pages.get(pageId);
        if (p) p.legendsOrderRev = o.rev;
      }
    }
    for (const [key, s] of Object.entries(d.settings as Record<string, Json>)) {
      if (!waiting.has(`setting:${key}`)) this.settings.set(key, { value: s.value, rev: s.rev });
    }
    this.rev = d.rev;
    this.needsFull = false;
  }

  /** What the screens show, comparable between phones. */
  view() {
    return {
      pages: [...this.pages].sort((a, b) => a[1].position - b[1].position || a[0].localeCompare(b[0]))
        .map(([id, p]) => ({ id, title: p.title, palette: p.palette, keepFree: p.keepFree })),
      legends: [...this.legends].sort((a, b) => a[1].pageId.localeCompare(b[1].pageId) || a[1].position - b[1].position)
        .map(([id, l]) => ({ id, pageId: l.pageId, color: l.color, label: l.label })),
      cells: [...this.cells].filter(([, c]) => c.color !== null).sort((a, b) => a[0].localeCompare(b[0]))
        .map(([key, c]) => [key, c.color, c.comment]),
      settings: Object.fromEntries([...this.settings].sort((a, b) => a[0].localeCompare(b[0])).map(([k, s]) => [k, s.value])),
    };
  }

  takeOutcomes(): Json[] {
    const told = this.outcomes;
    this.outcomes = [];
    return told;
  }
}

/** Both phones back online, queues sent: the same copy as the server's. */
async function converge(...phones: Phone[]) {
  for (const p of phones) { p.offline = false; await p.sync(); }
  for (const p of phones) await p.sync(); // what the others sent last
  const server = new Phone('server', phones[0].token);
  await server.pull();
  for (const p of phones) {
    assert.equal(p.queue.length, 0, `${p.name}: nothing left in the queue`);
    assert.deepEqual(p.view(), server.view(), `${p.name} ends with the server's copy`);
  }
}

const Y = new Date().getFullYear();
const day = (pageId: string, d: number, color: string, comment: string | null = null) => ({ pageId, year: Y, month: 1, day: d, color, comment });

async function newTracker(phone: Phone, title: string, legends: { color: string; label: string }[] = []) {
  const id = randomUUID();
  await phone.change('page.create', { id, title, legends: legends.map((l) => ({ id: randomUUID(), ...l })) });
  return id;
}

async function cleanup(a: Phone, b: Phone) {
  await converge(a, b);
  for (const id of [...a.pages.keys()]) await a.change('page.delete', { id });
  await converge(a, b);
  a.takeOutcomes();
  b.takeOutcomes();
}

async function main() {
  const health = await http('GET', '/api/health', null);
  assert.equal(health.status, 200, 'the server runs');

  const email = `scenarios-${Date.now()}@example.com`;
  const a = new Phone('A', await register(email));
  const b = new Phone('B', await login(email));
  const old = await login(email); // app 1.4.0, today's routes
  await converge(a, b);
  const results: string[] = [];
  const ok = (name: string) => { results.push(name); console.log(`  ✓ ${name}`); };

  // H17: a day coloured offline, changed elsewhere meanwhile: the server's stays, mine is given back.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    a.offline = true;
    await a.change('cell.set', day(t, 12, '#8CE99A', 'bonne journée'));
    await b.change('cell.set', day(t, 12, '#FFEC99'));
    await converge(a, b);
    const told = a.takeOutcomes();
    assert.equal(told.length, 1);
    assert.equal(told[0].status, 'changed');
    assert.deepEqual(told[0].current, { color: '#FFEC99', comment: null }, 'the version kept');
    assert.deepEqual(told[0].data.color, '#8CE99A', 'and mine, to do again');
    assert.equal(a.cells.get(cellKey(t, Y, 1, 12))?.color, '#FFEC99');
    await cleanup(a, b);
    ok('H17 a day changed elsewhere: the server\'s version stays, mine is told');
  }

  // H18: other days than those changed elsewhere: nothing is lost on either side.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    a.offline = true;
    await a.change('cell.set', day(t, 1, '#8CE99A'));
    await a.change('cell.set', day(t, 2, '#8CE99A'));
    await b.change('cell.set', day(t, 3, '#FFEC99'));
    await converge(a, b);
    assert.deepEqual(a.takeOutcomes(), [], 'no conflict');
    assert.deepEqual([1, 2, 3].map((d) => a.cells.get(cellKey(t, Y, 1, d))?.color), ['#8CE99A', '#8CE99A', '#FFEC99']);
    await cleanup(a, b);
    ok('H18 different days: everything is kept, element by element');
  }

  // H19: both offline on the same day: the first back wins, the second is told.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    a.offline = true;
    b.offline = true;
    await a.change('cell.set', day(t, 4, '#C92A2A'));
    await b.change('cell.set', day(t, 4, '#1864AB'));
    a.offline = false;
    await a.sync();
    assert.deepEqual(a.takeOutcomes(), [], 'the first back sends its version');
    b.offline = false;
    await b.sync();
    const told = b.takeOutcomes();
    assert.equal(told.length, 1);
    assert.equal(told[0].status, 'changed');
    await converge(a, b);
    assert.equal(b.cells.get(cellKey(t, Y, 1, 4))?.color, '#C92A2A');
    await cleanup(a, b);
    ok('H19 both offline on one day: the first back stays, the second is told');
  }

  // H20: days coloured offline in a tracker deleted elsewhere: gone everywhere, told once.
  {
    const t = await newTracker(b, 'Sport');
    await converge(a, b);
    a.offline = true;
    for (const d of [5, 6, 7]) await a.change('cell.set', day(t, d, '#2B8A3E'));
    await b.change('page.delete', { id: t });
    await converge(a, b);
    const told = a.takeOutcomes();
    assert.equal(told.length, 3);
    assert.ok(told.every((o) => o.status === 'deleted'));
    assert.equal(a.pages.has(t), false, 'the tracker is gone');
    assert.equal([...a.cells.keys()].some((k) => k.startsWith(t)), false, 'with its days');
    await cleanup(a, b);
    ok('H20 a tracker deleted elsewhere: the days coloured offline in it are told as not kept');
  }

  // H21: a deletion made offline of a tracker changed elsewhere is not applied.
  {
    const t = await newTracker(b, 'Sport');
    await converge(a, b);
    a.offline = true;
    await a.change('page.delete', { id: t });
    await b.change('cell.set', day(t, 8, '#2B8A3E'));
    await converge(a, b);
    const told = a.takeOutcomes();
    assert.deepEqual(told.map((o) => [o.kind, o.status]), [['page.delete', 'changed']]);
    assert.equal(a.pages.get(t)?.title, 'Sport', 'the tracker is back on the phone');
    assert.equal(a.cells.get(cellKey(t, Y, 1, 8))?.color, '#2B8A3E', 'with what the other phone added');
    await cleanup(a, b);
    ok('H21 a deletion made offline: not applied when the tracker changed elsewhere');
  }

  // H22: a name, a legend, an order, a setting changed both offline and elsewhere: the server's stays.
  {
    const t = await newTracker(b, 'Forme', [{ color: '#FFEC99', label: 'Bon' }]);
    const t2 = await newTracker(b, 'Lecture');
    await converge(a, b);
    const legendId = [...a.legends.keys()][0];
    a.offline = true;
    await a.change('page.update', { id: t, title: 'Fitness' });
    await a.change('legend.update', { id: legendId, label: 'Très bien' });
    await a.change('pages.reorder', { ids: [t2, t] });
    await a.change('setting.set', { key: 'theme', value: 'ocean' });
    await b.change('page.update', { id: t, title: 'Santé' });
    await b.change('legend.update', { id: legendId, label: 'Bien' });
    await b.change('pages.reorder', { ids: [t, t2] });
    await b.change('setting.set', { key: 'theme', value: 'sakura' });
    await converge(a, b);
    const told = a.takeOutcomes();
    assert.deepEqual(told.map((o) => [o.kind, o.status]), [
      ['page.update', 'changed'], ['legend.update', 'changed'], ['pages.reorder', 'changed'], ['setting.set', 'changed'],
    ]);
    assert.deepEqual(told[0].current, { title: 'Santé' }, '« Ce tracker s\'appelle « Santé » »');
    assert.equal(a.pages.get(t)?.title, 'Santé');
    assert.equal(a.legends.get(legendId)?.label, 'Bien');
    assert.deepEqual(a.view().pages.map((p) => p.id), [t, t2]);
    assert.equal(a.settings.get('theme')?.value, 'sakura');
    await cleanup(a, b);
    ok('H22 a name, a legend, an order, a setting: the version made elsewhere stays, each is told');
  }

  // H26: the other phone runs app 1.4.0: its changes count like any other device's.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    a.offline = true;
    await a.change('cell.set', day(t, 9, '#8CE99A'));
    await a.change('page.update', { id: t, title: 'Mood' });
    const put = await http('PUT', `/api/cells/${t}`, old, { year: Y, month: 1, day: 9, color: '#E599F7' });
    assert.equal(put.status, 200, `1.4.0 colours a day: ${JSON.stringify(put.json)}`);
    const rename = await http('PATCH', `/api/pages/${t}`, old, { title: 'Humeur du jour' });
    assert.equal(rename.status, 200);
    await converge(a, b);
    assert.deepEqual(a.takeOutcomes().map((o) => [o.kind, o.status]), [['cell.set', 'changed'], ['page.update', 'changed']]);
    assert.equal(a.cells.get(cellKey(t, Y, 1, 9))?.color, '#E599F7');
    assert.equal(a.pages.get(t)?.title, 'Humeur du jour');
    const legacy = await http('GET', `/api/cells/${t}?year=${Y}`, old);
    assert.deepEqual(legacy.json.map((c: Json) => [c.day, c.color]), [[9, '#E599F7']], '1.4.0 sees the same');
    await cleanup(a, b);
    ok('H26 an app 1.4.0 elsewhere: its changes win over what waited');
  }

  // H27: two phones online on the same day: the last writer wins, no message.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    await a.change('cell.set', day(t, 10, '#C92A2A'));
    await b.change('cell.set', day(t, 10, '#1864AB'));
    await converge(a, b);
    assert.deepEqual([...a.takeOutcomes(), ...b.takeOutcomes()], []);
    assert.equal(a.cells.get(cellKey(t, Y, 1, 10))?.color, '#1864AB');
    await cleanup(a, b);
    ok('H27 two phones online: the last writer wins, without a message');
  }

  // H28: the same day changed three times offline leaves once; an answer lost does not set the next aside.
  {
    const t = await newTracker(b, 'Humeur');
    await converge(a, b);
    a.offline = true;
    await a.change('cell.set', day(t, 11, '#C92A2A'));
    await a.change('cell.set', day(t, 11, '#1864AB'));
    await a.change('cell.set', day(t, 11, '#2B8A3E', 'final'));
    assert.equal(a.queue.length, 1, 'one change: the last state, with the first base');
    a.offline = false;
    await a.sync();
    assert.deepEqual(a.takeOutcomes(), []);
    // A change sent, its answer lost; the next one of that day must not lose to it.
    a.record('cell.set', day(t, 11, '#E599F7'));
    await a.sync({ loseAnswer: true });
    a.offline = true;
    await a.change('cell.set', day(t, 11, '#F08C00', 'after'));
    assert.equal(a.queue.length, 2, 'the sent one is not merged with the next');
    await converge(a, b);
    assert.deepEqual(a.takeOutcomes(), [], 'my own change never counts as made elsewhere');
    assert.deepEqual([a.cells.get(cellKey(t, Y, 1, 11))?.color, a.cells.get(cellKey(t, Y, 1, 11))?.comment], ['#F08C00', 'after']);
    await cleanup(a, b);
    ok('H28 one element changed several times offline, and a lost answer: nothing set aside');
  }

  // H29: a legend recoloured elsewhere: what I did offline on its days is kept, in the new colour.
  {
    const t = await newTracker(b, 'Humeur', [{ color: '#FFEC99', label: 'Bien' }]);
    const legendId = [...b.legends.keys()].find((id) => b.legends.get(id)!.pageId === t)!;
    await b.change('cell.set', day(t, 13, '#FFEC99'));
    await converge(a, b);
    a.offline = true;
    await a.change('cell.set', day(t, 13, '#FFEC99', 'un commentaire'));
    await a.change('cell.set', day(t, 14, '#FFEC99'));
    await b.change('legend.update', { id: legendId, color: '#74C0FC' });
    await converge(a, b);
    assert.deepEqual(a.takeOutcomes(), [], 'a recolour changes no day');
    assert.deepEqual([13, 14].map((d) => [a.cells.get(cellKey(t, Y, 1, d))?.color, a.cells.get(cellKey(t, Y, 1, d))?.comment]), [
      ['#74C0FC', 'un commentaire'],
      ['#74C0FC', null],
    ], 'kept, in the new colour');
    await cleanup(a, b);
    ok('H29 a legend recoloured elsewhere: the days changed offline are kept, in the new colour');
  }

  // H23: two trackers created offline on two phones go over the free limit: both kept.
  {
    const email2 = `scenarios-free-${Date.now()}@example.com`;
    const c = new Phone('C', await register(email2));
    const d = new Phone('D', await login(email2));
    await newTracker(c, 'Un');
    await newTracker(c, 'Deux');
    await converge(c, d);
    c.offline = true;
    d.offline = true;
    await newTracker(c, 'Trois');
    await newTracker(d, 'Quatre');
    await converge(c, d);
    assert.deepEqual([...c.takeOutcomes(), ...d.takeOutcomes()], [], 'a creation is never in conflict');
    assert.equal(c.pages.size, 4, 'both kept: nothing is erased');
    assert.equal([...c.pages.values()].some((p) => p.keepFree), false, 'the choice is the user\'s (the keep screen opens)');
    const fifth = await c.change('page.create', { id: randomUUID(), title: 'Cinq' });
    assert.deepEqual(c.takeOutcomes().map((o) => [o.kind, o.status, o.reason]), [['page.create', 'rejected', 'tracker_limit']], 'online, the limit holds');
    assert.ok(fifth);
    await converge(c, d);
    assert.equal((await http('DELETE', '/api/auth/account', c.token)).status, 200);
    ok('H23 two trackers created offline over the free limit: both kept, the limit holds online');
  }

  assert.equal((await http('DELETE', '/api/auth/account', a.token)).status, 200);
  console.log(`\n${results.length} scenarios passed.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
