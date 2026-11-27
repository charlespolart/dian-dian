/**
 * The changes a phone sends (offline sync, chantier 10): what they are, how
 * they are read, and how one is judged against what the server has.
 * Spec: docs/superpowers/specs/2026-11-26-offline-sync-design.md
 * ("Règles", "Le conflit"); plan: docs/superpowers/plans/2026-11-27-offline-sync.md.
 *
 * A change carries the number its element had on the phone when the gesture
 * was made (`base`), and whether it waited (made offline, or its first send
 * failed). One that waited is set aside when its element changed elsewhere
 * since: the server wins. One that did not wait is simply applied: two
 * phones online keep "the last writer wins".
 */
import { z } from 'zod';
import { maxFreeTrackers } from '../lib/premium.js';

const hex = z.string().regex(/^#[0-9A-Fa-f]{6}$/);
const id = z.string().uuid();
const date = { year: z.number().int().min(2000).max(2100), month: z.number().int().min(1).max(12), day: z.number().int().min(1).max(31) };
const palette = z.array(z.array(hex).length(6)).min(1).max(7);

/** The data of each kind of change. */
export const mutationData = {
  'cell.set': z.object({ pageId: id, ...date, color: hex, comment: z.string().max(200).nullable().optional() }).strict(),
  'cell.clear': z.object({ pageId: id, ...date }).strict(),
  'page.create': z.object({
    id,
    title: z.string().min(1).max(35),
    palette: palette.nullable().optional(),
    legends: z.array(z.object({ id, color: hex, label: z.string().min(1).max(30) }).strict()).max(12).optional(),
  }).strict(),
  'page.update': z.object({ id, title: z.string().min(1).max(35).optional(), palette: palette.nullable().optional() }).strict(),
  'page.delete': z.object({ id }).strict(),
  'pages.reorder': z.object({ ids: z.array(id).max(500) }).strict(),
  'pages.keep': z.object({ ids: z.array(id).max(maxFreeTrackers) }).strict(),
  'legend.create': z.object({ id, pageId: id, color: hex, label: z.string().min(1).max(30) }).strict(),
  'legend.update': z.object({ id, label: z.string().min(1).max(30).optional(), color: hex.optional() }).strict(),
  'legend.delete': z.object({ id }).strict(),
  'legends.reorder': z.object({ pageId: id, ids: z.array(id).max(12) }).strict(),
  'setting.set': z.discriminatedUnion('key', [
    z.object({ key: z.literal('theme'), value: z.string().min(1).max(50) }).strict(),
    z.object({ key: z.literal('language'), value: z.string().max(10).nullable() }).strict(),
    z.object({ key: z.literal('cursor'), value: z.object({ id: z.string().min(1).max(50), enabled: z.boolean() }).strict() }).strict(),
  ]),
} as const;

export type MutationKind = keyof typeof mutationData;
export const mutationKinds = Object.keys(mutationData) as MutationKind[];

export type Mutation = {
  id: string;
  kind: MutationKind;
  /** Made offline, or its first send failed: judged by the offline rule. */
  waited: boolean;
  /** The number of its element as the phone knew it; null for a creation. */
  base: number | null;
  data: Record<string, unknown>;
};

export type MutationResult =
  /** Applied; `revs` the numbers it left (the element's, its tracker's content, the account's). */
  | { id: string; status: 'applied'; revs: Record<string, number> }
  /** Set aside: the element changed elsewhere; `current` is what the server keeps. */
  | { id: string; status: 'changed'; current: unknown }
  /** Set aside: the element, or its tracker, was deleted elsewhere. */
  | { id: string; status: 'deleted' }
  /** Refused for a reason that is not a conflict (H12). */
  | { id: string; status: 'rejected'; reason: 'invalid' | 'legend_limit' | 'not_found' | 'locked' | 'tracker_limit' };

const envelope = z.object({
  id,
  kind: z.enum(mutationKinds as [MutationKind, ...MutationKind[]]),
  waited: z.boolean(),
  base: z.number().int().min(0).nullable(),
  data: z.record(z.unknown()),
}).strict();

/** A change as sent by a phone, or null when it cannot be read. */
export function parseMutation(raw: unknown): Mutation | null {
  const outer = envelope.safeParse(raw);
  if (!outer.success) return null;
  const inner = mutationData[outer.data.kind].safeParse(outer.data.data);
  if (!inner.success) return null;
  return { ...outer.data, data: inner.data as Record<string, unknown> };
}

const creations: ReadonlySet<MutationKind> = new Set(['page.create', 'legend.create']);
const dayKinds: ReadonlySet<MutationKind> = new Set(['cell.set', 'cell.clear']);

/**
 * What the server has of a change's element.
 * - `exists`: the element is there (for a day: it is coloured).
 * - `editRev`: the number the offline rule compares — the element's edit
 *   number; for a day cleared since, the number of its trace; for a tracker
 *   deleted by the change, its content number; for an order, a choice or a
 *   setting, its number on the account or the tracker.
 * - `tombstoned`: the element itself was deleted (a trace exists).
 * - `parentGone`: the tracker it belongs to is gone.
 */
export type ElementState = { exists: boolean; editRev: number; tombstoned: boolean; parentGone: boolean };

/** Apply the change, or set it aside: the offline rule (spec, "Le conflit"). */
export function judge(m: Mutation, el: ElementState): 'apply' | 'changed' | 'deleted' {
  // Nothing is written into a tracker that is gone, waited or not (H20).
  if (el.parentGone) return 'deleted';
  // A creation is never in conflict, but never brings back what was deleted
  // since; sent again after a lost answer, it finds its element and is
  // applied (the caller makes that a no-op).
  if (creations.has(m.kind)) return el.tombstoned ? 'deleted' : 'apply';
  // A day always "exists" for the rule: colouring an empty day creates it.
  if (!dayKinds.has(m.kind) && !el.exists) return 'deleted';
  if (!m.waited) return 'apply';
  return el.editRev === m.base ? 'apply' : 'changed';
}

/**
 * The order a phone sends, against the ids the server has (in their current
 * order): the listed ones first, in the sent order, then the others in
 * theirs — a tracker created elsewhere meanwhile is not lost; an id the
 * server does not have is dropped.
 */
export function mergeOrder(listed: string[], existing: string[]): string[] {
  const known = new Set(existing);
  const first = listed.filter((id, i) => known.has(id) && listed.indexOf(id) === i);
  const placed = new Set(first);
  return [...first, ...existing.filter((id) => !placed.has(id))];
}
