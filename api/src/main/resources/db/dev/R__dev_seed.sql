-- =============================================================
-- K-Budget — Dev Seed Data (repeatable migration)
-- Profil dev uniquement (classpath:db/dev)
-- =============================================================

DO $$
DECLARE
    v_user_id UUID;
    v_compte_eur UUID;
    v_compte_xof UUID;
    v_cat_alimentation UUID;
    v_cat_transport UUID;
    v_cat_loisirs UUID;
    v_cat_sante UUID;
    v_cat_logement UUID;
    v_cat_salaire UUID;
    v_cat_freelance UUID;
    v_cat_abonnement UUID;
    v_cat_dette UUID;
    v_cat_courses UUID;
    v_cat_restaurant UUID;
BEGIN
    -- Recuperer le user existant
    SELECT id INTO v_user_id FROM users LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Aucun utilisateur en base. Creer un compte via /api/auth/register d''abord.';
    END IF;

    -- ===========================================================
    -- CATEGORIES (custom, en plus des systeme)
    -- ===========================================================
    INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
    VALUES
        (gen_random_uuid(), 'Alimentation', '🛒', '#22c55e', false, v_user_id),
        (gen_random_uuid(), 'Transport', '🚗', '#3b82f6', false, v_user_id),
        (gen_random_uuid(), 'Loisirs', '🎮', '#a855f7', false, v_user_id),
        (gen_random_uuid(), 'Sante', '🏥', '#ef4444', false, v_user_id),
        (gen_random_uuid(), 'Logement', '🏠', '#f97316', false, v_user_id),
        (gen_random_uuid(), 'Salaire', '💼', '#10b981', false, v_user_id),
        (gen_random_uuid(), 'Freelance', '💻', '#6366f1', false, v_user_id),
        (gen_random_uuid(), 'Courses', '🧺', '#14b8a6', false, v_user_id),
        (gen_random_uuid(), 'Restaurant', '🍽️', '#f59e0b', false, v_user_id)
    ON CONFLICT DO NOTHING;

    -- Recuperer les IDs categories
    SELECT id INTO v_cat_alimentation FROM categories WHERE nom = 'Alimentation' AND user_id = v_user_id;
    SELECT id INTO v_cat_transport FROM categories WHERE nom = 'Transport' AND user_id = v_user_id;
    SELECT id INTO v_cat_loisirs FROM categories WHERE nom = 'Loisirs' AND user_id = v_user_id;
    SELECT id INTO v_cat_sante FROM categories WHERE nom = 'Sante' AND user_id = v_user_id;
    SELECT id INTO v_cat_logement FROM categories WHERE nom = 'Logement' AND user_id = v_user_id;
    SELECT id INTO v_cat_salaire FROM categories WHERE nom = 'Salaire' AND user_id = v_user_id;
    SELECT id INTO v_cat_freelance FROM categories WHERE nom = 'Freelance' AND user_id = v_user_id;
    SELECT id INTO v_cat_abonnement FROM categories WHERE nom = 'Abonnement' AND user_id = v_user_id;
    SELECT id INTO v_cat_dette FROM categories WHERE nom = 'Dette' AND user_id = v_user_id;
    SELECT id INTO v_cat_courses FROM categories WHERE nom = 'Courses' AND user_id = v_user_id;
    SELECT id INTO v_cat_restaurant FROM categories WHERE nom = 'Restaurant' AND user_id = v_user_id;

    -- ===========================================================
    -- COMPTES (2 : EUR + XOF)
    -- ===========================================================
    -- Supprimer les comptes seed precedents pour rendre le script repeatable
    DELETE FROM transactions WHERE account_id IN (
        SELECT id FROM accounts WHERE user_id = v_user_id AND nom IN ('Compte Courant', 'Compte CFA')
    );
    DELETE FROM accounts WHERE user_id = v_user_id AND nom IN ('Compte Courant', 'Compte CFA');

    v_compte_eur := gen_random_uuid();
    v_compte_xof := gen_random_uuid();

    INSERT INTO accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, currency, bank_code, user_id)
    VALUES
        (v_compte_eur, 'Compte Courant', 'COURANT', 2450.00, '🏦', '#3b82f6', true, true, 'EUR', 'BNP', v_user_id),
        (v_compte_xof, 'Compte CFA', 'COURANT', 850000, '🌍', '#f59e0b', false, true, 'XOF', 'OTHER', v_user_id);

    -- Desactiver l'ancien compte par defaut
    UPDATE accounts SET is_default = false
    WHERE user_id = v_user_id AND id != v_compte_eur;

    -- ===========================================================
    -- TAUX DE CHANGE
    -- ===========================================================
    INSERT INTO exchange_rates (id, user_id, base_currency, target_currency, rate)
    VALUES (gen_random_uuid(), v_user_id, 'EUR', 'XOF', 655.957)
    ON CONFLICT (user_id, base_currency, target_currency) DO UPDATE SET rate = 655.957;

    -- ===========================================================
    -- USER PREFERENCES
    -- ===========================================================
    UPDATE user_preferences
    SET currencies = 'EUR,XOF',
        enabled_features = 'SUBSCRIPTIONS,DEBTS',
        timezone = 'Europe/Paris'
    WHERE user_id = v_user_id;

    -- ===========================================================
    -- TRANSACTIONS EUR — Mars 2026
    -- ===========================================================
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    -- Revenus
    (gen_random_uuid(), 2800.00, 'Salaire Mars', 'RECETTE', '2026-03-01', NULL, v_user_id, v_cat_salaire, v_compte_eur),
    (gen_random_uuid(), 450.00, 'Mission freelance', 'RECETTE', '2026-03-10', 'Client Dupont', v_user_id, v_cat_freelance, v_compte_eur),
    -- Depenses
    (gen_random_uuid(), 750.00, 'Loyer mars', 'DEPENSE', '2026-03-01', NULL, v_user_id, v_cat_logement, v_compte_eur),
    (gen_random_uuid(), 85.50, 'Carrefour', 'DEPENSE', '2026-03-03', NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 42.00, 'Essence', 'DEPENSE', '2026-03-05', NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 120.00, 'Medecin + pharmacie', 'DEPENSE', '2026-03-07', NULL, v_user_id, v_cat_sante, v_compte_eur),
    (gen_random_uuid(), 35.90, 'Lidl', 'DEPENSE', '2026-03-09', NULL, v_user_id, v_cat_courses, v_compte_eur),
    (gen_random_uuid(), 28.50, 'Sushi Shop', 'DEPENSE', '2026-03-12', NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 65.00, 'Cinema + bowling', 'DEPENSE', '2026-03-15', NULL, v_user_id, v_cat_loisirs, v_compte_eur),
    (gen_random_uuid(), 92.30, 'Courses semaine', 'DEPENSE', '2026-03-17', NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 15.00, 'Uber', 'DEPENSE', '2026-03-19', NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 48.00, 'Restaurant italien', 'DEPENSE', '2026-03-22', NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 110.00, 'Courses Auchan', 'DEPENSE', '2026-03-25', NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 55.00, 'Plein essence', 'DEPENSE', '2026-03-28', NULL, v_user_id, v_cat_transport, v_compte_eur);

    -- TRANSACTIONS EUR — Fevrier 2026
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 2800.00, 'Salaire Fevrier', 'RECETTE', '2026-02-01', NULL, v_user_id, v_cat_salaire, v_compte_eur),
    (gen_random_uuid(), 750.00, 'Loyer fevrier', 'DEPENSE', '2026-02-01', NULL, v_user_id, v_cat_logement, v_compte_eur),
    (gen_random_uuid(), 95.00, 'Courses Carrefour', 'DEPENSE', '2026-02-04', NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 38.00, 'Essence', 'DEPENSE', '2026-02-08', NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 22.00, 'Kebab + tacos', 'DEPENSE', '2026-02-10', NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 180.00, 'Dentiste', 'DEPENSE', '2026-02-14', NULL, v_user_id, v_cat_sante, v_compte_eur),
    (gen_random_uuid(), 73.50, 'Courses semaine', 'DEPENSE', '2026-02-18', NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 40.00, 'Jeux video', 'DEPENSE', '2026-02-21', NULL, v_user_id, v_cat_loisirs, v_compte_eur),
    (gen_random_uuid(), 52.00, 'Plein essence', 'DEPENSE', '2026-02-25', NULL, v_user_id, v_cat_transport, v_compte_eur);

    -- ===========================================================
    -- TRANSACTIONS XOF — Mars 2026
    -- ===========================================================
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 350000, 'Virement famille', 'RECETTE', '2026-03-02', NULL, v_user_id, v_cat_salaire, v_compte_xof),
    (gen_random_uuid(), 45000, 'Marche Assigame', 'DEPENSE', '2026-03-04', NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(), 15000, 'Taxi-moto', 'DEPENSE', '2026-03-06', NULL, v_user_id, v_cat_transport, v_compte_xof),
    (gen_random_uuid(), 75000, 'Loyer local', 'DEPENSE', '2026-03-01', NULL, v_user_id, v_cat_logement, v_compte_xof),
    (gen_random_uuid(), 8500, 'Pharmacie', 'DEPENSE', '2026-03-11', NULL, v_user_id, v_cat_sante, v_compte_xof),
    (gen_random_uuid(), 25000, 'Marche Hedzranawoe', 'DEPENSE', '2026-03-15', NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(), 12000, 'Maquis', 'DEPENSE', '2026-03-18', NULL, v_user_id, v_cat_restaurant, v_compte_xof),
    (gen_random_uuid(), 35000, 'Courses semaine', 'DEPENSE', '2026-03-22', NULL, v_user_id, v_cat_courses, v_compte_xof),
    (gen_random_uuid(), 5000, 'Zem', 'DEPENSE', '2026-03-26', NULL, v_user_id, v_cat_transport, v_compte_xof);

    -- ===========================================================
    -- ABONNEMENTS
    -- ===========================================================
    DELETE FROM subscriptions WHERE user_id = v_user_id AND nom IN ('Netflix', 'Spotify', 'Canal+', 'Orange Fibre');

    INSERT INTO subscriptions (id, nom, montant, frequence, date_debut, actif, user_id, category_id, account_id, currency) VALUES
    (gen_random_uuid(), 'Netflix', 13.49, 'MENSUEL', '2025-06-01', true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Spotify', 10.99, 'MENSUEL', '2025-01-15', true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Canal+', 25.99, 'MENSUEL', '2025-09-01', true, v_user_id, v_cat_abonnement, v_compte_xof, 'XOF'),
    (gen_random_uuid(), 'Orange Fibre', 29.99, 'MENSUEL', '2025-03-10', true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR');

    -- ===========================================================
    -- DETTES
    -- ===========================================================
    DELETE FROM debts WHERE user_id = v_user_id AND personne IN ('Kofi', 'Marie', 'Papa');

    INSERT INTO debts (id, personne, montant, sens, date, due_date, rembourse, user_id, category_id, account_id, currency) VALUES
    (gen_random_uuid(), 'Kofi', 150000, 'PRET', '2026-02-15', '2026-04-15', false, v_user_id, v_cat_dette, v_compte_xof, 'XOF'),
    (gen_random_uuid(), 'Marie', 200.00, 'EMPRUNT', '2026-03-01', '2026-05-01', false, v_user_id, v_cat_dette, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Papa', 500.00, 'EMPRUNT', '2026-01-10', '2026-03-10', true, v_user_id, v_cat_dette, v_compte_eur, 'EUR');

    -- ===========================================================
    -- BUDGETS
    -- ===========================================================
    DELETE FROM budgets WHERE user_id = v_user_id;

    INSERT INTO budgets (id, montant, currency, frequence, seuil_notification, actif, category_id, user_id) VALUES
    (gen_random_uuid(), 400.00, 'EUR', 'MENSUEL', 80, true, v_cat_alimentation, v_user_id),
    (gen_random_uuid(), 150.00, 'EUR', 'MENSUEL', 75, true, v_cat_transport, v_user_id),
    (gen_random_uuid(), 100.00, 'EUR', 'MENSUEL', 90, true, v_cat_loisirs, v_user_id),
    (gen_random_uuid(), 200.00, 'EUR', 'MENSUEL', 80, true, v_cat_restaurant, v_user_id),
    (gen_random_uuid(), 120000, 'XOF', 'MENSUEL', 80, true, v_cat_courses, v_user_id);

    -- ===========================================================
    -- RECURRING TRANSACTIONS
    -- ===========================================================
    DELETE FROM transactions WHERE user_id = v_user_id AND is_recurring = true AND libelle IN ('Loyer', 'Assurance auto');

    INSERT INTO transactions (id, montant, libelle, type, date, user_id, category_id, account_id, is_recurring, frequency, next_occurrence, recurring_active) VALUES
    (gen_random_uuid(), 750.00, 'Loyer', 'DEPENSE', '2026-03-01', v_user_id, v_cat_logement, v_compte_eur, true, 'MENSUEL', '2026-04-01', true),
    (gen_random_uuid(), 45.00, 'Assurance auto', 'DEPENSE', '2026-03-15', v_user_id, v_cat_transport, v_compte_eur, true, 'MENSUEL', '2026-04-15', true);

    RAISE NOTICE 'Dev seed OK — user: %, EUR: %, XOF: %', v_user_id, v_compte_eur, v_compte_xof;
END $$;
