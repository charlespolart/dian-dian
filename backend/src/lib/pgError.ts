/**
 * Reading a failed database write: was it the row, or the moment?
 *
 * drizzle wraps the driver's error (the cause carries PostgreSQL's SQLSTATE,
 * five characters); an error with no SQLSTATE is not the database's answer
 * at all — a connection that dropped, a value that could not even be sent.
 * Classes: https://www.postgresql.org/docs/16/errcodes-appendix.html
 */
const SQLSTATE = /^[0-9A-Z]{5}$/;

export function sqlState(err: unknown): string | null {
  for (const candidate of [err, (err as { cause?: unknown } | null | undefined)?.cause]) {
    const code = (candidate as { code?: unknown } | null | undefined)?.code;
    if (typeof code === 'string' && SQLSTATE.test(code)) return code;
  }
  return null;
}

/**
 * Failures of the moment, which a second try may not meet: connection (08),
 * transaction rolled back by the database (40: serialization, deadlock),
 * out of resources (53), cancelled or shut down (57), lock not available.
 */
const PASSING = (state: string) => ['08', '40', '53', '57'].includes(state.slice(0, 2)) || state === '55P03';

/**
 * Whether the database refused the write for what it was asked to write, and
 * would again: a character it cannot store, a value too long, a reference to
 * a row deleted since — or a table or a column that is not there, after a
 * rollback of the code but not of the request. False for a failure of the
 * moment and for anything that is not the database's answer.
 */
export function refusesTheRow(err: unknown): boolean {
  const state = sqlState(err);
  return state !== null && !PASSING(state);
}
