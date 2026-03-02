#!/usr/bin/env python3
"""
Normalise les libellés des transactions importées depuis le relevé LCL.
Transforme les libellés bruts bancaires en libellés humains lisibles.
Utilise le champ `note` comme source pour détecter les patterns.
"""

import os
import re
import sys
from typing import Optional, List, Dict, Tuple
import requests

BASE_URL = "https://budget.kksdev.fr/api"
EMAIL = "sopequeno.tech@gmail.com"
PASSWORD = None  # sera demandé interactivement

# ─── Mapping commercants bruts → noms propres ───────────────────────────────

MERCHANT_MAP = {
    "UEP*SUPER U": "Super U",
    "APPLE.COM/BILL": "Apple",
    "APPLE COMMERCE": "Apple",
    "AMZ DIGITAL FRA": "Amazon Digital",
    "AMAZON EU SARL": "Amazon",
    "AMAZON PAYMENTS": "Amazon",
    "CHICKEN DRIVE IS": "Chicken Drive",
    "CLAUDE.AI SUBSCRIPTION": "Claude AI",
    "WESTERN UNION COMMERCE": "Western Union",
    "LIGNE WEB SERVI": "Ligne Web Services",
    "SNCF VOYAGEURS": "SNCF",
    "SNCF-VOYAGEURS": "SNCF",
    "PIMKIE 0232": "Pimkie",
    "NORMAL VENDENHEIM PROMEN": "Normal",
    "INTERMARCHE STATION": "Intermarche",
    "CARREFOUR MARKET": "Carrefour Market",
    "AVANT ET MAINTENANT": "Avant et Maintenant",
    "BP ORCHAMPS DAC": "BP (station)",
    "ARCOS ITTENHEIM BARRIERE": "Peage Arcos",
    "ASF-SALON OUEST": "Peage ASF",
    "DR TANAPAKIUM": "Dr Tanapakium",
    "PARIT1 COMPTOIRS": "Comptoirs de la Bio",
    "SC MOULIN BERGE": "Moulin Berge",
    "SAS FRANCHARD": "Hotel Franchard",
    "ALTERNA COMMERCE": "Alterna",
}

# Patterns partiels (match par startswith/contains)
MERCHANT_PATTERNS = [
    ("UBER   *TRIP", "Uber (trajet)"),
    ("UBER   *ONE MEMBERSHIP", "Uber One"),
    ("UBER   *EATS", "Uber Eats"),
    ("UBER   *ONE", "Uber One"),
    ("Lydia*Lydia Solut", "Transfert Lydia"),
    ("VETMT MEM'MODE", "Mem'Mode"),
    ("GC RE PLUM", "Plum"),
    ("RELAY ", "Relay"),
    ("NIKE0", "Nike"),
    ("HAVAIANAS", "Havaianas"),
    ("TUBISTRES", "Tubistres"),
    ("SumUp  *Llanos", "Llanos"),
    ("aliexpress", "AliExpress"),
    ("Boulangerie patisserie", "Boulangerie"),
    ("Zalando Payments", "Zalando"),
    ("APRR AUTOROUTE", "Peage APRR"),
    ("APRR LA COTIERE", "Peage APRR"),
    ("APRR", "Peage APRR"),
    ("PRET SOGEFINANC.EXPRESSO", "Sofinco Expresso"),
    ("PRET SOGEFINANC.ALTERNA", "Sofinco Alterna"),
    ("Younited", "Younited Credit"),
    ("Free Telecom", "Free (box)"),
    ("FREE MOBILE", "Free Mobile"),
    ("Alterna Energie", "Alterna Energie"),
]

MOIS_FR = {
    1: "Janvier", 2: "Fevrier", 3: "Mars", 4: "Avril",
    5: "Mai", 6: "Juin", 7: "Juillet", 8: "Aout",
    9: "Septembre", 10: "Octobre", 11: "Novembre", 12: "Decembre",
}


def extract_merchant_from_card(note: str) -> Optional[str]:
    """Extrait le nom du commercant depuis une note de paiement par carte.

    Formats:
      CARTE X3855 DD/MM MERCHANT XXXXXXXXXXXXXXXIOPD
      CARTE X3855 DD/MM MERCHANT AMOUNT EUR COUNTRY COMMERCE ELECTRONIQUE XXXXXXXXXXXXXXXIOPD
      CARTE X3855 REMBT DD/MM MERCHANT ... XXXXXXXXXXXXILIC
    """
    # Extraire tout apres la date DD/MM
    m = re.search(r'CARTE\s+X\d{4}\s+(?:REMBT\s+)?\d{2}/\d{2}\s+(.+)', note, re.IGNORECASE)
    if not m:
        return None

    raw = m.group(1).strip()

    # Retirer le code IOPD/ILIC en fin (9+ chiffres suivis de IOPD ou ILIC)
    raw = re.sub(r'\s*\d{9,}(?:IOPD|ILIC)\s*$', '', raw, flags=re.IGNORECASE)
    # Retirer "COMMERCE ELECTRONIQUE" en fin
    raw = re.sub(r'\s+COMMERCE\s+ELECTRONIQUE\s*$', '', raw, flags=re.IGNORECASE)
    # Retirer le pattern montant+devise+pays en fin : "25,95 EUR IRLANDE"
    raw = re.sub(r'\s+\d+,\d+\s+EUR\s+[\w\s\'\-]+$', '', raw, flags=re.IGNORECASE)

    return raw.strip() if raw.strip() else None


def clean_merchant(name: str) -> str:
    """Normalise un nom de commercant brut en nom propre lisible."""
    name = name.strip()
    name_upper = name.upper()

    # Exact match d'abord
    for brut, clean in MERCHANT_MAP.items():
        if brut.upper() == name_upper:
            return clean

    # Pattern match (case-insensitive contains)
    for pattern, clean in MERCHANT_PATTERNS:
        if name_upper.startswith(pattern.upper()) or pattern.upper() in name_upper:
            return clean

    # Nettoyage generique
    cleaned = name
    # Retirer les suffixes numeriques type "0232", "4067420"
    cleaned = re.sub(r'\s+\d{4,}$', '', cleaned)
    # Title case si tout en majuscules et plus de 3 caracteres
    if cleaned == cleaned.upper() and len(cleaned) > 3:
        cleaned = cleaned.title()
    return cleaned


def extract_name_from_pour(note: str) -> Optional[str]:
    """Extrait le nom apres POUR: dans une note de virement.

    Exemples:
      POUR: JESSICA H IBAN: ... → "JESSICA H"
      POUR: Jean-charles Chaillot 29 01 BQ 1348500800 CPT ... REF: ... → "Jean-charles Chaillot"
      POUR: M. KOMLA SOSSOE REF: ... → "M. KOMLA SOSSOE"
    """
    m = re.search(r'POUR:\s*(.+?)(?:\s+IBAN:|\s+REF:|\s+\d{2}\s+\d{2}\s+BQ|\s*$)', note)
    if m:
        name = m.group(1).strip()
        name = re.sub(r'\s+MOTIF:.*', '', name)
        name = re.sub(r'\s+ID:.*', '', name)
        return name.strip()
    return None


def extract_name_from_de(note: str) -> Optional[str]:
    """Extrait le nom apres DE: dans une note de virement recu.

    Exemples:
      DE: CARSAT SUD EST REF: SALAIRE → "CARSAT SUD EST"
      DE: MR SALIM BRAHIMI DATE: 13/02/2026 ... → "MR SALIM BRAHIMI"
      DE: M. KOMLA SOSSOE MOTIF: ... → "M. KOMLA SOSSOE"
    """
    m = re.search(r'DE:\s*(.+?)(?:\s+(?:MOTIF|DATE|ID|REF):|\s*$)', note)
    if m:
        name = m.group(1).strip()
        return name.strip()
    return None


def extract_creditor_from_de(note: str) -> Optional[str]:
    """Extrait le creancier apres DE: dans un prelevement."""
    m = re.search(r'DE:\s*(.+?)(?:\s+ID:|$)', note)
    if m:
        name = m.group(1).strip()
        name = re.sub(r'\s+REF:.*', '', name)
        name = re.sub(r'\s+MOTIF:.*', '', name)
        return name.strip()
    return None


def normalize_creditor(creditor: str) -> str:
    """Normalise le nom d'un creancier de prelevement."""
    c = creditor.upper().strip()
    mapping = {
        "FREE MOBILE": "Free Mobile",
        "FREE TELECOM": "Free (box)",
        "ALTERNA ENERGIE": "Alterna Energie",
    }
    for pattern, clean in mapping.items():
        if pattern in c:
            return clean

    for pattern, clean in MERCHANT_PATTERNS:
        if pattern.upper() in c:
            return clean

    # Title case par defaut
    return creditor.strip().title()


def format_prenom_initial(name: str) -> str:
    """Formate un nom en 'Prenom N.' pour les virements wero."""
    parts = name.strip().split()
    if len(parts) >= 2:
        prenom = parts[0].capitalize()
        initial = parts[-1][0].upper() + "."
        return f"{prenom} {initial}"
    return name.strip().capitalize()


def normalize_label(note: Optional[str], libelle: str, date_str: str) -> Optional[str]:
    """
    Retourne le libelle normalise, ou None si pas de transformation applicable.
    L'ordre des checks est important : les patterns les plus specifiques d'abord.
    """
    if not note:
        return None

    note_upper = note.upper()

    # ── FRAIS ET COTISATIONS (avant CARTE car COMMISSION contient "CARTE X") ──

    if "AVANTAGE COMMERCIAL" in note_upper and "SOBRIO" in note_upper:
        return "Avantage Sobrio (-50%)"

    if "COMMISSION D" in note_upper and "INTERVENTION" in note_upper:
        return "Commission d'intervention"

    if "COTISATION MENSUELLE SOBRIO" in note_upper:
        return "Cotisation Sobrio"

    if "COTIS OPTION VOYAGEUR" in note_upper:
        return "Cotisation Visa Premier"

    if "FRAIS PRELEVEMENT IMPAYE" in note_upper:
        return "Frais prelevement impaye"

    if "FRAIS SUR SATD" in note_upper:
        return "Frais SATD"

    if "LETTRE INFO COMPTE" in note_upper:
        return "Frais lettre compte debiteur"

    if "ARRETE" in note_upper and "MINIMUM FORFAITAIRE" in note_upper:
        return "Agios trimestriels"

    # ── CARTE X3855 ──

    if "CARTE X" in note_upper:
        # Retrait DAB
        if "RETRAIT DAB" in note_upper:
            return "Retrait distributeur"

        # Transfert Lydia
        if "TRANSF" in note_upper and "LYDIA" in note_upper:
            return "Transfert Lydia"

        # Remboursement
        if "REMBT" in note_upper:
            merchant = extract_merchant_from_card(note)
            if merchant:
                return f"Remboursement {clean_merchant(merchant)}"
            return "Remboursement"

        # Achat par carte
        merchant = extract_merchant_from_card(note)
        if merchant:
            return clean_merchant(merchant)

    # ── VIREMENTS EMIS ──

    if "VIR INSTANTANE EMIS" in note_upper or "VIR INST EM" in note_upper:
        name = extract_name_from_pour(note)
        if name:
            return f"Virement a {format_prenom_initial(name)}"
        return "Virement Wero" if "WERO" in note_upper else "Virement instantane"

    if "VIR EUROPEEN EMIS" in note_upper or "VIR EUR EMIS" in note_upper:
        name = extract_name_from_pour(note)
        if name:
            return f"Virement a {name.title()}"
        return "Virement europeen"

    if "VIR PERM" in note_upper:
        name = extract_name_from_pour(note)
        if name:
            return f"Virement permanent {name.title()}"
        return "Virement permanent"

    # ── VIREMENTS RECUS ──

    if ("VIR RECU" in note_upper or "VIR EUR RECU" in note_upper) and "SALAIRE" in note_upper:
        if date_str:
            parts = date_str.split("-")
            if len(parts) == 3:
                mois = int(parts[1])
                annee = parts[0]
                return f"Salaire {MOIS_FR.get(mois, '')} {annee}"
        return "Salaire"

    if ("VIR INST RE" in note_upper or "VIR INSTANTANE RECU" in note_upper) and "PLUM" in note_upper:
        return "Virement Plum"

    if "VIR RECU" in note_upper or "VIR EUR RECU" in note_upper or "VIR INST RE" in note_upper or "VIR INSTANTANE RECU" in note_upper:
        name = extract_name_from_de(note)
        if name:
            return f"Virement de {name.title()}"
        return "Virement recu"

    # VIR OPTION ALTERNA
    if "VIR OPTION ALTERNA" in note_upper:
        return "Virement epargne Alterna"

    # ── PRELEVEMENTS ──

    if "PRELEVEMENT EUROPEEN" in note_upper or "PRELEVEMENT SEPA" in note_upper:
        creditor = extract_creditor_from_de(note)
        if creditor:
            return f"Prelevement {normalize_creditor(creditor)}"
        return "Prelevement"

    return None


def login(session: requests.Session) -> str:
    """Authentification et retourne le token JWT."""
    resp = session.post(f"{BASE_URL}/auth/login", json={
        "email": EMAIL,
        "password": PASSWORD,
    })
    resp.raise_for_status()
    data = resp.json()
    return data["token"]


def refresh_auth(session: requests.Session) -> str:
    """Re-authentification pour renouveler le token."""
    return login(session)


def get_all_transactions(session: requests.Session, token: str) -> List[dict]:
    """Recupere toutes les transactions."""
    resp = session.get(
        f"{BASE_URL}/transactions",
        headers={"Authorization": f"Bearer {token}"},
    )
    resp.raise_for_status()
    return resp.json()


def update_transaction(session: requests.Session, token: str, tx: dict, new_label: str) -> bool:
    """Met a jour le libelle d'une transaction."""
    payload = {
        "montant": tx["montant"],
        "libelle": new_label,
        "type": tx["type"],
        "date": tx["date"],
        "categoryId": tx["category"]["id"] if tx.get("category") else None,
        "note": tx.get("note"),
        "accountId": tx["account"]["id"] if tx.get("account") else None,
    }
    resp = session.put(
        f"{BASE_URL}/transactions/{tx['id']}",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    if resp.status_code == 200:
        return True
    else:
        print(f"  ERREUR {resp.status_code}: {resp.text[:200]}")
        return False


def main():
    global PASSWORD

    if len(sys.argv) > 1 and sys.argv[1] == "--dry-run":
        dry_run = True
        print("=== MODE DRY-RUN (aucune modification) ===\n")
    else:
        dry_run = False

    # Mot de passe via variable d'environnement ou argument
    PASSWORD = os.environ.get("BUDGET_PASSWORD")
    if not PASSWORD:
        if len(sys.argv) > 2:
            PASSWORD = sys.argv[2]
        elif len(sys.argv) > 1 and sys.argv[1] != "--dry-run":
            PASSWORD = sys.argv[1]
    if not PASSWORD:
        try:
            import getpass
            PASSWORD = getpass.getpass(f"Mot de passe pour {EMAIL}: ")
        except EOFError:
            print("ERREUR: Definir BUDGET_PASSWORD ou passer le mot de passe en argument")
            print("  BUDGET_PASSWORD=xxx python3 scripts/normalize_labels.py --dry-run")
            sys.exit(1)

    session = requests.Session()

    # Auth
    print("Authentification...")
    token = login(session)
    print("OK\n")

    # Recuperer les transactions
    print("Recuperation des transactions...")
    transactions = get_all_transactions(session, token)
    print(f"{len(transactions)} transactions recuperees\n")

    # Normaliser
    changes = []
    skipped = 0

    for tx in transactions:
        old_label = tx["libelle"]
        note = tx.get("note")
        date_str = tx.get("date", "")

        new_label = normalize_label(note, old_label, date_str)

        if new_label and new_label != old_label:
            changes.append((tx, old_label, new_label))
        else:
            skipped += 1

    print(f"{len(changes)} transactions a normaliser, {skipped} inchangees\n")

    if not changes:
        print("Rien a faire.")
        return

    # Afficher un echantillon
    print("=== Echantillon (20 premiers) ===")
    for tx, old, new in changes[:20]:
        print(f"  [{tx['date']}] \"{old}\" → \"{new}\"")
    print()

    if dry_run:
        print(f"=== DRY-RUN: {len(changes)} modifications auraient ete faites ===")
        print("\n=== Toutes les modifications ===")
        for tx, old, new in changes:
            print(f"  [{tx['date']}] \"{old}\" → \"{new}\"")
        return

    # Confirmation (skip si --yes)
    if "--yes" not in sys.argv:
        confirm = input(f"Appliquer {len(changes)} modifications ? (oui/non): ")
        if confirm.lower() not in ("oui", "o", "yes", "y"):
            print("Annule.")
            return

    # Appliquer les modifications
    success = 0
    errors = 0
    batch_size = 80

    for i, (tx, old, new) in enumerate(changes):
        # Re-auth toutes les 80 requetes
        if i > 0 and i % batch_size == 0:
            print(f"\n  Re-authentification ({i}/{len(changes)})...")
            token = refresh_auth(session)

        if update_transaction(session, token, tx, new):
            success += 1
            print(f"  [{success}/{len(changes)}] \"{old}\" → \"{new}\"")
        else:
            errors += 1
            print(f"  ERREUR pour tx {tx['id']}: \"{old}\"")

    print(f"\n=== Resultat ===")
    print(f"  Succes: {success}")
    print(f"  Erreurs: {errors}")
    print(f"  Inchangees: {skipped}")


if __name__ == "__main__":
    main()
