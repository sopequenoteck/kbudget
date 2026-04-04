-- =============================================================
-- K-Budget — Seed Avril 2026 (1er au 3 avril)
-- Transactions vie courante réaliste
-- =============================================================

DO $$
DECLARE
    v_user_id UUID;
    v_compte_eur UUID;
    v_compte_xof UUID;
    v_cat_alimentation UUID;
    v_cat_transport UUID;
    v_cat_logement UUID;
    v_cat_restaurant UUID;
    v_cat_courses UUID;
    v_cat_salaire UUID;
    v_cat_abonnement UUID;
BEGIN
    -- Recuperer le user existant
    SELECT id INTO v_user_id FROM users LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Aucun utilisateur en base.';
    END IF;

    -- Recuperer les comptes
    SELECT id INTO v_compte_eur FROM accounts WHERE user_id = v_user_id AND currency = 'EUR' AND nom = 'Compte Courant';
    SELECT id INTO v_compte_xof FROM accounts WHERE user_id = v_user_id AND currency = 'XOF' AND nom = 'Compte CFA';

    -- Recuperer les categories
    SELECT id INTO v_cat_alimentation FROM categories WHERE nom = 'Alimentation' AND user_id = v_user_id;
    SELECT id INTO v_cat_transport FROM categories WHERE nom = 'Transport' AND user_id = v_user_id;
    SELECT id INTO v_cat_logement FROM categories WHERE nom = 'Logement' AND user_id = v_user_id;
    SELECT id INTO v_cat_restaurant FROM categories WHERE nom = 'Restaurant' AND user_id = v_user_id;
    SELECT id INTO v_cat_courses FROM categories WHERE nom = 'Courses' AND user_id = v_user_id;
    SELECT id INTO v_cat_salaire FROM categories WHERE nom = 'Salaire' AND user_id = v_user_id;
    SELECT id INTO v_cat_abonnement FROM categories WHERE nom = 'Abonnement' AND user_id = v_user_id;

    -- ===========================================================
    -- TRANSACTIONS EUR — Avril 2026 (1er au 3)
    -- ===========================================================
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    -- 1er avril : salaire + loyer + courses
    (gen_random_uuid(), 2800.00, 'Salaire Avril',       'RECETTE', '2026-04-01', NULL,               v_user_id, v_cat_salaire,      v_compte_eur),
    (gen_random_uuid(),  750.00, 'Loyer avril',          'DEPENSE', '2026-04-01', NULL,               v_user_id, v_cat_logement,     v_compte_eur),
    (gen_random_uuid(),   29.99, 'Orange Fibre',         'DEPENSE', '2026-04-01', 'Prelevement auto', v_user_id, v_cat_abonnement,   v_compte_eur),
    -- 2 avril : courses + transport
    (gen_random_uuid(),   67.40, 'Carrefour Market',     'DEPENSE', '2026-04-02', NULL,               v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(),    1.90, 'Ticket metro',         'DEPENSE', '2026-04-02', NULL,               v_user_id, v_cat_transport,    v_compte_eur),
    (gen_random_uuid(),   12.50, 'Boulangerie',          'DEPENSE', '2026-04-02', NULL,               v_user_id, v_cat_alimentation, v_compte_eur),
    -- 3 avril : resto midi + courses
    (gen_random_uuid(),   14.90, 'Dejeuner kebab',       'DEPENSE', '2026-04-03', NULL,               v_user_id, v_cat_restaurant,   v_compte_eur),
    (gen_random_uuid(),   43.20, 'Lidl',                 'DEPENSE', '2026-04-03', NULL,               v_user_id, v_cat_courses,      v_compte_eur),
    (gen_random_uuid(),   48.00, 'Plein essence',        'DEPENSE', '2026-04-03', NULL,               v_user_id, v_cat_transport,    v_compte_eur);

    -- ===========================================================
    -- TRANSACTIONS XOF — Avril 2026 (1er au 3)
    -- ===========================================================
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    -- 1er avril : loyer local
    (gen_random_uuid(), 75000, 'Loyer local avril',    'DEPENSE', '2026-04-01', NULL, v_user_id, v_cat_logement,     v_compte_xof),
    -- 2 avril : marche
    (gen_random_uuid(), 18500, 'Marche Assigame',      'DEPENSE', '2026-04-02', NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(),  3500, 'Zem trajet',           'DEPENSE', '2026-04-02', NULL, v_user_id, v_cat_transport,    v_compte_xof),
    -- 3 avril : courses + maquis
    (gen_random_uuid(), 12000, 'Courses marche',       'DEPENSE', '2026-04-03', NULL, v_user_id, v_cat_courses,      v_compte_xof),
    (gen_random_uuid(),  4500, 'Maquis midi',          'DEPENSE', '2026-04-03', NULL, v_user_id, v_cat_restaurant,   v_compte_xof);

    RAISE NOTICE 'Seed avril OK — user: %, EUR: %, XOF: %', v_user_id, v_compte_eur, v_compte_xof;
END $$;
