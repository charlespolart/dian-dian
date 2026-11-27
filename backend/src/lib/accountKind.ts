/**
 * Invisible or attached: the server says it (chantier 9, principle 5). An
 * account is attached as soon as it has an identity — an address, a
 * password, an Apple or Google sign-in — and invisible otherwise; the app
 * never guesses it from what it kept.
 */
export type Method = 'email' | 'password' | 'apple' | 'google';

export function accountKind(
  user: { email: string | null; passwordHash: string | null },
  providers: string[],
): { kind: 'invisible' | 'attached'; methods: Method[] } {
  const methods: Method[] = [];
  if (user.email) methods.push('email');
  if (user.passwordHash) methods.push('password');
  for (const provider of ['apple', 'google'] as const) {
    if (providers.includes(provider)) methods.push(provider);
  }
  return { kind: methods.length === 0 ? 'invisible' : 'attached', methods };
}
