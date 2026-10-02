/**
 * Vrai si `url` est une URL interne de l'application (chemin absolu du site),
 * donc utilisable comme `returnUrl` apres connexion. Refuse les URL absolues
 * (`https://...`) et relatives au protocole (`//...`, `/\...`) : redirection
 * ouverte vers un site tiers.
 */
export function isInternalReturnUrl(url: string): boolean {
  const isInternalUrl = url.startsWith('/') && !url.startsWith('//') && !url.startsWith('/\\');
  const isNotAbsolute = !/^https?:/i.test(url);
  return isInternalUrl && isNotAbsolute;
}
