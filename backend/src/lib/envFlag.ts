/**
 * An on/off setting read from the environment. `on`, `true`, `1`, `yes` turn
 * it on; `off`, `false`, `0`, `no` turn it off; anything else — absent,
 * empty, a typo — keeps the default, so that a value written the way another
 * tool expects it never silently means the opposite.
 */
export function envFlag(value: string | undefined, fallback: boolean): boolean {
  const said = (value ?? '').trim().toLowerCase();
  if (['on', 'true', '1', 'yes'].includes(said)) return true;
  if (['off', 'false', '0', 'no'].includes(said)) return false;
  return fallback;
}
