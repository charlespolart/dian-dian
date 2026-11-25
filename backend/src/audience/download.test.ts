import assert from 'node:assert/strict';
import { test } from 'node:test';
import { download, plainAddress } from './download.js';

const LIMITS = { maxBytes: 1_000, timeoutMs: 1_000 };
/** A response whose body says whether it was read to the end or cancelled. */
function watched(status: number, bytes: number) {
  const state = { cancelled: false, pulled: 0 };
  const body = new ReadableStream<Uint8Array>({
    pull(controller) {
      state.pulled++;
      if (state.pulled * 100 > bytes) controller.close();
      else controller.enqueue(new Uint8Array(100));
    },
    cancel() { state.cancelled = true; },
  });
  return { state, fetcher: (async () => new Response(body, { status })) as unknown as typeof fetch };
}

test('a file within the limits comes back whole', async () => {
  const { fetcher } = watched(200, 500);
  assert.equal((await download(fetcher, 'https://example.com/x', LIMITS))?.length, 500);
});

test('an error answer is not read: its body is cancelled, the connection is not left hanging', async () => {
  const { fetcher, state } = watched(500, 500);
  assert.equal(await download(fetcher, 'https://example.com/x', LIMITS), null);
  assert.equal(state.cancelled, true);
});

test('a body larger than the limit is cut off, not read to its end', async () => {
  const { fetcher, state } = watched(200, 1_000_000);
  assert.equal(await download(fetcher, 'https://example.com/x', LIMITS), null);
  assert.equal(state.cancelled, true);
  assert.ok(state.pulled < 20, `${state.pulled} chunks read`);
});

test('a fetch that throws gives nothing, never an exception', async () => {
  assert.equal(await download((async () => { throw new Error('ENOTFOUND'); }) as unknown as typeof fetch, 'https://example.com/x', LIMITS), null);
});

test('an IPv4 address written as IPv6 is that IPv4 address', () => {
  assert.equal(plainAddress('::ffff:203.0.113.7'), '203.0.113.7');
  assert.equal(plainAddress('::FFFF:203.0.113.7'), '203.0.113.7');
  assert.equal(plainAddress('2001:db8::1'), '2001:db8::1');
  assert.equal(plainAddress(undefined), '');
});
