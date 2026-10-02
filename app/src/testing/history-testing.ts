/**
 * Utilitaires des specs d'historique (KKS-447) : jsdom execute `history.go` / `history.back` en
 * differe, puis emet `popstate`. Un test doit donc attendre avant de conclure.
 */

const SETTLE_TIMEOUT_MS = 30;

/** Attend le prochain `popstate`, ou la fin du delai s'il n'en vient aucun. */
function nextPopState(timeoutMs: number): Promise<void> {
  return new Promise((resolve) => {
    const timer = setTimeout(done, timeoutMs);
    function done(): void {
      clearTimeout(timer);
      removeEventListener('popstate', done);
      resolve();
    }
    addEventListener('popstate', done, { once: true });
  });
}

/**
 * Laisse le temps a jsdom de traverser l'historique et d'emettre `popstate` (apres le microtask
 * de reconciliation du service). Sans traversee attendue, le delai complet s'ecoule.
 */
export async function settleHistory(): Promise<void> {
  await Promise.resolve();
  await nextPopState(SETTLE_TIMEOUT_MS);
}

/** Remet l'URL a la racine et l'etat a zero entre deux tests. */
export function resetHistory(): void {
  history.replaceState(null, '', '/');
}

/** Simule le geste de retour de l'utilisateur et attend son `popstate`, ecouteurs inclus. */
export async function goBack(): Promise<void> {
  const popped = nextPopState(1000);
  history.back();
  await popped;
}
