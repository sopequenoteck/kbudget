// jsdom ne fournit pas IntersectionObserver, dont les ecrans de liste se
// servent pour leur en-tete collant (sticky-sentinel). Aucun test n'observe
// d'intersection : le bouchon ne fait rien.
class IntersectionObserverStub {
  observe(): void {
    // rien a observer sous jsdom
  }

  unobserve(): void {
    // rien a observer sous jsdom
  }

  disconnect(): void {
    // rien a observer sous jsdom
  }

  takeRecords(): unknown[] {
    return [];
  }
}

export function stubIntersectionObserver(): void {
  vi.stubGlobal('IntersectionObserver', IntersectionObserverStub);
}
