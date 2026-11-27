import { refusesTheRow } from '../lib/pgError.js';

/**
 * Whether a change failed for what it is, and would fail again: the
 * database refusing what it was asked to write, or a bug in the code that
 * applies it. Such a change is refused (`rejected`, `invalid`) so that the
 * phone's queue moves on; anything else is a failure of the moment, and the
 * batch is answered 500 for the phone to send again (review, minor 8).
 */
export function refusedForGood(err: unknown): boolean {
  return refusesTheRow(err) || err instanceof TypeError || err instanceof RangeError;
}
