#!/usr/bin/env bash
# Extrait les notes d'une version du CHANGELOG pour la GitHub Release (KKS-492).
#
# Usage : release-notes.sh <version> [changelog]   (defaut : CHANGELOG.md)
#
# Ecrit sur stdout : le bloc `## [<version>]` (jusqu'au titre `## ` suivant,
# sans les lignes de definition de liens), la liste des images Docker, puis un
# lien vers le changelog francais. Echoue si le bloc est introuvable ou vide.
set -euo pipefail

VERSION="${1:-}"
CHANGELOG="${2:-CHANGELOG.md}"

if [ -z "${VERSION}" ]; then
  echo "ERREUR: version vide. Usage : $0 <version> [changelog]" >&2
  exit 1
fi

if [ ! -f "${CHANGELOG}" ]; then
  echo "ERREUR: ${CHANGELOG} introuvable." >&2
  exit 1
fi

# Titre et version passes par l'environnement : awk -v interprete les
# sequences d'echappement. Comparaison en chaine fixe (index), jamais en regex :
# 6.1.0 ne doit pas matcher 6.10.0, ni 6.10.0 matcher 6x10x0.
if ! grep -qF -- "## [${VERSION}]" "${CHANGELOG}"; then
  echo "ERREUR: titre '## [${VERSION}]' absent de ${CHANGELOG}." >&2
  exit 1
fi

BLOCK=$(
  NOTES_HEADING="## [${VERSION}]" awk '
    BEGIN { heading = ENVIRON["NOTES_HEADING"]; inblock = 0 }
    {
      sub(/\r$/, "")
      if (!inblock) {
        # Titre exact : "## [x.y.z]" suivi de la fin de ligne ou d un espace.
        if (substr($0, 1, length(heading)) == heading) {
          rest = substr($0, length(heading) + 1)
          if (rest == "" || substr(rest, 1, 1) == " ") { inblock = 1 }
        }
        next
      }
      if ($0 ~ /^## /) { exit }
      if ($0 ~ /^\[[^]]+\]: https?:\/\//) { next }
      print
    }
  ' "${CHANGELOG}" \
  | awk '
      { lines[NR] = $0 }
      END {
        first = 1
        while (first <= NR && lines[first] ~ /^[[:space:]]*$/) first++
        last = NR
        while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
        for (i = first; i <= last; i++) print lines[i]
      }'
)

if [ -z "${BLOCK}" ]; then
  echo "ERREUR: le bloc '## [${VERSION}]' de ${CHANGELOG} est vide." >&2
  exit 1
fi

printf '%s\n\n' "${BLOCK}"
cat <<NOTES
### Docker images

- \`ghcr.io/sopequenoteck/k-budget-api:${VERSION}\`
- \`ghcr.io/sopequenoteck/k-budget-app:${VERSION}\`

🇫🇷 [Notes de version en français](https://github.com/sopequenoteck/kbudget/blob/v${VERSION}/CHANGELOG.fr.md)
NOTES
