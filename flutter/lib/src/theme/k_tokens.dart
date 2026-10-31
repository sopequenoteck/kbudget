// K Design v0.7.1 — généré par scripts/build.mjs depuis tokens.json. Ne pas éditer.
// ignore_for_file: constant_identifier_names

import 'dart:ui';

import 'package:flutter/animation.dart' show Cubic;

/// Tokens K Design. Thème sombre en premier : `xxxDark` / `xxxLight`.
class KTokens {
  KTokens._();

  // ----- Couleurs -----
  /// Primitive. Texte principal en sombre (via text-primary). Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray50Dark = Color(0xFFFAFAFA);
  static const Color gray50Light = Color(0xFFFAFAFA);
  /// Primitive. Surface raised et hover en clair. Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray100Dark = Color(0xFFF5F5F5);
  static const Color gray100Light = Color(0xFFF5F5F5);
  /// Primitive. Bordure par défaut en clair. Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray200Dark = Color(0xFFE5E5E5);
  static const Color gray200Light = Color(0xFFE5E5E5);
  /// Primitive. Bordure forte en clair. Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray300Dark = Color(0xFFD4D4D4);
  static const Color gray300Light = Color(0xFFD4D4D4);
  /// Primitive. Texte secondaire en sombre.
  static const Color gray400Dark = Color(0xFFA3A3A3);
  static const Color gray400Light = Color(0xFFA3A3A3);
  /// Primitive de la palette grise, sans emploi sémantique depuis D4.
  static const Color gray500Dark = Color(0xFF737373);
  static const Color gray500Light = Color(0xFF737373);
  /// Primitive. Texte secondaire en clair ; bordure forte en sombre. Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray600Dark = Color(0xFF525252);
  static const Color gray600Light = Color(0xFF525252);
  /// Primitive. Surface raised, bordure et hover en sombre (#1e1e1e). Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray700Dark = Color(0xFF1E1E1E);
  static const Color gray700Light = Color(0xFF1E1E1E);
  /// Primitive. Surface default en sombre (#141414). Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray800Dark = Color(0xFF141414);
  static const Color gray800Light = Color(0xFF141414);
  /// Primitive. Fond de page en sombre (#0a0a0a) ; texte principal en clair. Ne jamais l'employer directement dans un composant : passer par un token sémantique.
  static const Color gray900Dark = Color(0xFF0A0A0A);
  static const Color gray900Light = Color(0xFF0A0A0A);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber50Dark = Color(0xFFFFFBEB);
  static const Color amber50Light = Color(0xFFFFFBEB);
  /// Primitive. color-primary-light du thème clair.
  static const Color amber100Dark = Color(0xFFFEF3C7);
  static const Color amber100Light = Color(0xFFFEF3C7);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber200Dark = Color(0xFFFDE68A);
  static const Color amber200Light = Color(0xFFFDE68A);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber300Dark = Color(0xFFFCD34D);
  static const Color amber300Light = Color(0xFFFCD34D);
  /// Primitive. Base de l'anneau de focus en sombre. Réservée aux tokens sémantiques.
  static const Color amber400Dark = Color(0xFFFBBF24);
  static const Color amber400Light = Color(0xFFFBBF24);
  /// Primitive. Base de l'anneau de focus en clair.
  static const Color amber500Dark = Color(0xFFF59E0B);
  static const Color amber500Light = Color(0xFFF59E0B);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber600Dark = Color(0xFFD97706);
  static const Color amber600Light = Color(0xFFD97706);
  /// Primitive. color-primary-hover du thème clair. Réservée aux tokens sémantiques.
  static const Color amber700Dark = Color(0xFFB45309);
  static const Color amber700Light = Color(0xFFB45309);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber800Dark = Color(0xFF92400E);
  static const Color amber800Light = Color(0xFF92400E);
  /// Primitive de la palette ambre. Réservée aux tokens sémantiques.
  static const Color amber900Dark = Color(0xFF78350F);
  static const Color amber900Light = Color(0xFF78350F);
  /// Primitive feedback succès, base des fonds bg-success en sombre.
  static const Color colorSuccessRawDark = Color(0xFF22C55E);
  static const Color colorSuccessRawLight = Color(0xFF22C55E);
  /// Primitive feedback avertissement, base de bg-warning en sombre.
  static const Color colorWarningRawDark = Color(0xFFEAB308);
  static const Color colorWarningRawLight = Color(0xFFEAB308);
  /// Primitive feedback erreur, base de bg-error en sombre.
  static const Color colorErrorRawDark = Color(0xFFEF4444);
  static const Color colorErrorRawLight = Color(0xFFEF4444);
  /// Primitive feedback information, base de bg-info en sombre.
  static const Color colorInfoRawDark = Color(0xFF3B82F6);
  static const Color colorInfoRawLight = Color(0xFF3B82F6);
  /// Fond global de la page. Élévation 0.
  static const Color bgPrimaryDark = Color(0xFF0A0A0A);
  static const Color bgPrimaryLight = Color(0xFFF0F0F0);
  /// Fond des champs de formulaire (input, select, textarea).
  static const Color bgSecondaryDark = Color(0xFF141414);
  static const Color bgSecondaryLight = Color(0xFFFFFFFF);
  /// Fond des champs dans un bottom sheet (bsheet__input, recherche category-select).
  static const Color bgTertiaryDark = Color(0xFF1E1E1E);
  static const Color bgTertiaryLight = Color(0xFFF5F5F5);
  /// Contenu : conteneur de liste groupée, cards, listbox. Élévation 1.
  static const Color surfaceDefaultDark = Color(0xFF141414);
  static const Color surfaceDefaultLight = Color(0xFFFFFFFF);
  /// Chrome : en-tête, barre du bas, FAB, section header collée, confirm dialog, overlay autocomplete. Élévation 2.
  static const Color surfaceRaisedDark = Color(0xFF1E1E1E);
  static const Color surfaceRaisedLight = Color(0xFFF5F5F5);
  /// Fond transparent du section header non collé (source : transparent).
  static const Color surfaceBackgroundDark = Color(0x00000000);
  static const Color surfaceBackgroundLight = Color(0x00000000);
  /// Voile derrière un bottom sheet, un dialog ou le speed-dial du FAB.
  static const Color surfaceOverlayDark = Color.fromRGBO(0, 0, 0, 0.6);
  static const Color surfaceOverlayLight = Color.fromRGBO(10, 10, 10, 0.5);
  /// Pastille d'un interrupteur, posée sur sa piste (k-color-primary activé, k-border-strong désactivé). D15 : blanche dans les deux thèmes ; l'état est porté par la couleur de la piste.
  static const Color switchThumbDark = Color(0xFFFFFFFF);
  static const Color switchThumbLight = Color(0xFFFFFFFF);
  /// Texte principal : titres de page, montants neutres, valeurs saisies. Sur bg-primary, surface-default et surface-raised.
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textPrimaryLight = Color(0xFF0A0A0A);
  /// Titres de rangée, titres de section, libellés de champ. Sur bg-primary, surface-default et surface-raised.
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color textSecondaryLight = Color(0xFF525252);
  /// Méta, dates, conversions de devise, labels uppercase, placeholders. D4 : 5,2:1 sur surface-raised en sombre, 5,1:1 sur surface-raised en clair (AA).
  static const Color textTertiaryDark = Color(0xFF8A8A8A);
  static const Color textTertiaryLight = Color(0xFF6B6B6B);
  /// Texte posé sur un aplat plein (btn-danger).
  static const Color textInverseDark = Color(0xFF0A0A0A);
  static const Color textInverseLight = Color(0xFFFFFFFF);
  /// Séparateurs entre rangées, bordure des pills et boutons ronds, bordure des champs.
  static const Color borderDefaultDark = Color(0xFF1E1E1E);
  static const Color borderDefaultLight = Color(0xFFE5E5E5);
  /// Bordure renforcée, rare.
  static const Color borderStrongDark = Color(0xFF525252);
  static const Color borderStrongLight = Color(0xFFD4D4D4);
  /// Canal Action : CTA, FAB, toggles actifs, liens, onglet actif, date du jour. Jamais décoratif. D1/D2 : 8,6:1 sur surface-default en sombre ; 3,9:1 sur blanc en clair (suffisant pour un indicateur, pas pour du texte courant).
  static const Color colorPrimaryDark = Color(0xFFE0A820);
  static const Color colorPrimaryLight = Color(0xFFC66E05);
  /// Survol de btn-primary.
  static const Color colorPrimaryHoverDark = Color(0xFFC9952A);
  static const Color colorPrimaryHoverLight = Color(0xFFB45309);
  /// Halo de focus des champs, survol des pills primaires.
  static const Color colorPrimaryLightDark = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color colorPrimaryLightLight = Color(0xFFFEF3C7);
  /// Texte sur un aplat color-primary (btn-primary, sélection). D2 : sombre dans les deux thèmes, 5,6:1 sur #c66e05 en clair.
  static const Color colorPrimaryContrastDark = Color(0xFF0A0A0A);
  static const Color colorPrimaryContrastLight = Color(0xFF0A0A0A);
  /// Fond d'un message de succès.
  static const Color bgSuccessDark = Color.fromRGBO(34, 197, 94, 0.1);
  static const Color bgSuccessLight = Color(0xFFDCFCE7);
  /// Fond d'un message d'erreur, survol des actions de suppression.
  static const Color bgErrorDark = Color.fromRGBO(239, 68, 68, 0.1);
  static const Color bgErrorLight = Color(0xFFFEE2E2);
  /// Fond d'un avertissement.
  static const Color bgWarningDark = Color.fromRGBO(234, 179, 8, 0.1);
  static const Color bgWarningLight = Color(0xFFFEF9C3);
  /// Fond d'une information.
  static const Color bgInfoDark = Color.fromRGBO(59, 130, 246, 0.1);
  static const Color bgInfoLight = Color(0xFFDBEAFE);
  /// Texte de succès sur bg-success ou une surface. D13 : valeur claire relevée au cran 700/800 pour passer 4,5:1 sur les fonds de page, surfaces et fond de feedback.
  static const Color textSuccessDark = Color(0xFF6DC990);
  static const Color textSuccessLight = Color(0xFF166534);
  /// Texte d'erreur de champ et de formulaire ; fond de btn-danger. D13 : valeur claire relevée au cran 700/800 pour passer 4,5:1 sur les fonds de page, surfaces et fond de feedback.
  static const Color textErrorDark = Color(0xFFD97777);
  static const Color textErrorLight = Color(0xFFB91C1C);
  /// Texte d'avertissement. D13 : valeur claire relevée au cran 700/800 pour passer 4,5:1 sur les fonds de page, surfaces et fond de feedback.
  static const Color textWarningDark = Color(0xFFD4AD3C);
  static const Color textWarningLight = Color(0xFF854D0E);
  /// Texte d'information. D13 : valeur claire relevée au cran 700/800 pour passer 4,5:1 sur les fonds de page, surfaces et fond de feedback.
  static const Color textInfoDark = Color(0xFF7AACDB);
  static const Color textInfoLight = Color(0xFF1D4ED8);
  /// Fond des cercles d'icône 36px des rangées et des en-têtes.
  static const Color iconCircleBgDark = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color iconCircleBgLight = Color.fromRGBO(0, 0, 0, 0.04);
  /// Survol des rangées et boutons.
  static const Color hoverBgDark = Color(0xFF1E1E1E);
  static const Color hoverBgLight = Color(0xFFF5F5F5);
  /// Survol très léger (4%).
  static const Color hoverSubtleDark = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color hoverSubtleLight = Color.fromRGBO(0, 0, 0, 0.04);
  /// Retour visuel d'appui.
  static const Color highlightSubtleDark = Color.fromRGBO(255, 255, 255, 0.1);
  static const Color highlightSubtleLight = Color.fromRGBO(0, 0, 0, 0.06);
  /// Voile clair ponctuel.
  static const Color overlayLightDark = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color overlayLightLight = Color.fromRGBO(0, 0, 0, 0.1);
  /// Sélection légère (catégorie sélectionnée).
  static const Color primarySubtleDark = Color.fromRGBO(224, 168, 32, 0.1);
  static const Color primarySubtleLight = Color.fromRGBO(198, 110, 5, 0.1);
  /// Fond des boutons soft ambre.
  static const Color primaryMutedDark = Color.fromRGBO(224, 168, 32, 0.15);
  static const Color primaryMutedLight = Color.fromRGBO(198, 110, 5, 0.15);
  /// Bordure ambre atténuée.
  static const Color primaryBorderDark = Color.fromRGBO(224, 168, 32, 0.25);
  static const Color primaryBorderLight = Color.fromRGBO(198, 110, 5, 0.25);
  /// Anneau de focus atténué. Le focus clavier global reste un outline 2px color-primary.
  static const Color focusRingDark = Color.fromRGBO(251, 191, 36, 0.5);
  static const Color focusRingLight = Color.fromRGBO(245, 158, 11, 0.5);
  /// Canal Revenu : montants positifs, prêts, solde positif. Alias de k-text-success.
  static const Color colorIncomeDark = Color(0xFF6DC990);
  static const Color colorIncomeLight = Color(0xFF166534);
  /// Canal Dépense : solde négatif, montant de dépense saisi, retard, suppression. Alias de k-text-error. En liste, une dépense reste en k-text-secondary.
  static const Color colorExpenseDark = Color(0xFFD97777);
  static const Color colorExpenseLight = Color(0xFFB91C1C);
  /// Dette que je dois (emprunt).
  static const Color colorDebtOweDark = Color(0xFFD97777);
  static const Color colorDebtOweLight = Color(0xFFB91C1C);
  /// Dette qu'on me doit (prêt).
  static const Color colorDebtOwedDark = Color(0xFF6DC990);
  static const Color colorDebtOwedLight = Color(0xFF166534);
  /// Marqueur des abonnements (violet). Propre à K·Budget, D7.
  static const Color colorSubscriptionDark = Color(0xFF9580D9);
  static const Color colorSubscriptionLight = Color(0xFF8B5CF6);

  // ----- Espacements (px) -----
  /// Aucun espacement.
  static const double space0 = 0;
  /// 4px. Gap icône–texte des méta-lignes, marges fines.
  static const double space1 = 4;
  /// 8px. Gap du hero, padding vertical des section headers, gap du bottom sheet.
  static const double space2 = 8;
  /// 12px. Padding vertical des rangées, gap icône–contenu, padding des champs.
  static const double space3 = 12;
  /// 16px. Padding horizontal des rangées et des champs, gouttière de page, padding du confirm.
  static const double space4 = 16;
  /// 20px. Padding horizontal des boutons, padding des pages d'auth.
  static const double space5 = 20;
  /// 24px. Bas du hero, marge des retours de navigation.
  static const double space6 = 24;
  /// 28px.
  static const double space7 = 28;
  /// 32px. Respiration entre le hero et les sections, haut des pages d'auth, entre sections de formulaire.
  static const double space8 = 32;
  /// 36px. Padding gauche d'un champ avec icône préfixe.
  static const double space9 = 36;
  /// 40px. Padding vertical des empty states et états de chargement.
  static const double space10 = 40;
  /// 44px.
  static const double space11 = 44;
  /// 48px.
  static const double space12 = 48;

  // ----- Rayons (px) -----
  /// 4px. Lignes de skeleton.
  static const double radiusSm = 4;
  /// 8px. Overlay d'autocomplete, message d'erreur d'auth.
  static const double radiusMd = 8;
  /// 12px. Speed-dial du FAB, erreur de bottom sheet.
  static const double radiusLg = 12;
  /// 16px. Conteneur de liste groupée, champs, boutons pleins, confirm dialog, coins hauts du bottom sheet.
  static const double radiusXl = 16;
  /// Pills, boutons ronds, cercles d'icône, handle, toggle.
  static const double radiusRound = 999;

  // ----- Tailles de police (px) -----
  /// 10px. Texte des tool-pills du bottom sheet.
  static const double fontSize2xs = 10;
  /// 12px. Montants de rangée, labels uppercase, méta, dates, conversions.
  static const double fontSizeXs = 12;
  /// 14px. Titres de rangée, libellés de champ, boutons pills, messages d'empty state.
  static const double fontSizeSm = 14;
  /// 16px. Corps, titres de section, champs.
  static const double fontSizeBase = 16;
  /// 18px. Titre de page (page-header).
  static const double fontSizeLg = 18;
  /// 20px. h3.
  static const double fontSizeXl = 20;
  /// 24px. h2.
  static const double fontSize2xl = 24;
  /// 30px. Montant hero, wordmark d'auth, h1.
  static const double fontSize3xl = 30;

  // ----- Graisses -----
  /// Corps, méta.
  static const int fontWeightNormal = 400;
  /// Titres de rangée, montants de rangée, labels, pills.
  static const int fontWeightMedium = 500;
  /// Titres de section, titres h1–h4, boutons pleins.
  static const int fontWeightSemibold = 600;
  /// Montant hero, titre de page, titre de bottom sheet.
  static const int fontWeightBold = 700;

  // ----- Interlignages (facteur) -----
  /// Titres h1–h4.
  static const double lineHeightTight = 1.25;
  /// Corps, champs, boutons.
  static const double lineHeightNormal = 1.5;
  /// Texte long, rare.
  static const double lineHeightRelaxed = 1.75;

  // ----- Mouvement (D20) -----
  /// Retours immédiats : survol, appui, bascule d'un interrupteur.
  static const Duration durationFast = Duration(milliseconds: 120);
  /// Transitions courantes : ouverture d'un menu, d'une feuille, d'un panneau.
  static const Duration durationNormal = Duration(milliseconds: 200);
  /// Mouvements amples et rares : entrée d'un écran, déplacement d'un bloc.
  static const Duration durationSlow = Duration(milliseconds: 400);
  /// Courbe par défaut, pour un élément qui change d'état sur place.
  static const Cubic easingDefault = Cubic(0.4, 0, 0.2, 1);
  /// Élément qui sort de l'écran.
  static const Cubic easingIn = Cubic(0.4, 0, 1, 1);
  /// Élément qui entre à l'écran.
  static const Cubic easingOut = Cubic(0, 0, 0.2, 1);

  static const String fontFamily = 'Inter Variable';
}
