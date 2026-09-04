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
    v_user_admin UUID;
    v_user_invite UUID;
    v_other UUID;
    v_compte_autre UUID;
    v_cat_autre_salaire UUID;
    v_cat_autre_courses UUID;
    v_cat_restaurant UUID;
BEGIN
    -- =============================================================
    -- USER DE DEV GENERIQUE
    -- Email    : dev@local.test
    -- Password : dev123 (hash BCrypt ci-dessous)
    -- Ce user est cree automatiquement pour permettre le demarrage
    -- de l'app en dev sans passer par /api/auth/register manuellement.
    -- NE JAMAIS utiliser ce hash/password en production.
    -- =============================================================

    -- 1. Creer le user dev s'il n'existe pas (idempotent)
    INSERT INTO users (id, email, password, name, created_at)
    VALUES (
        gen_random_uuid(),
        'dev@local.test',
        '$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq',
        'Dev User',
        NOW()
    )
    ON CONFLICT (email) DO NOTHING;

    -- Recuperer l'ID du user dev
    SELECT id INTO v_user_id FROM users WHERE email = 'dev@local.test';

    -- 2. Categories systeme (reproduit CategoryService.seedSystemCategories)
    --    is_system = true, idempotent : INSERT uniquement si la categorie n'existe pas deja
    --    (l'index unique est sur LOWER(nom), user_id — index partiel, pas de contrainte nommee)
    INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
    SELECT gen_random_uuid(), 'Abonnement', '🔄', '#6366f1', true, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM categories WHERE LOWER(nom) = 'abonnement' AND user_id = v_user_id);

    INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
    SELECT gen_random_uuid(), 'Dette', '💰', '#ef4444', true, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM categories WHERE LOWER(nom) = 'dette' AND user_id = v_user_id);

    INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
    SELECT gen_random_uuid(), 'Virement', '🔄', '#8b5cf6', true, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM categories WHERE LOWER(nom) = 'virement' AND user_id = v_user_id);

    -- 3. Compte principal EUR (reproduit AccountService.createDefaultAccount)
    --    bank_code = 'OTHER', is_default = true
    --    idempotent : INSERT uniquement si le compte n'existe pas deja (meme logique que l'index partiel)
    INSERT INTO accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, currency, bank_code, user_id)
    SELECT gen_random_uuid(), 'Compte Principal', 'COURANT', 0.00, '🏦', '#3b82f6', true, true, 'EUR', 'OTHER', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE LOWER(nom) = 'compte principal' AND user_id = v_user_id AND actif = true);

    -- 4. Preferences initiales (reproduit PreferenceService.createInitialPreference)
    --    enabled_features et nav_order = SUBSCRIPTIONS,DEBTS
    --    currencies = EUR, timezone = Europe/Paris
    --    idempotent via contrainte UNIQUE sur user_id
    INSERT INTO user_preferences (id, user_id, enabled_features, nav_order, currencies, timezone, text_scale)
    VALUES (
        gen_random_uuid(),
        v_user_id,
        'SUBSCRIPTIONS,DEBTS',
        'SUBSCRIPTIONS,DEBTS',
        'EUR',
        'Europe/Paris',
        'MEDIUM'
    )
    ON CONFLICT (user_id) DO NOTHING;

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
    (gen_random_uuid(), 2800.00, 'Salaire Mars', 'RECETTE', (CURRENT_DATE - INTERVAL '36 days'), NULL, v_user_id, v_cat_salaire, v_compte_eur),
    (gen_random_uuid(), 450.00, 'Mission freelance', 'RECETTE', (CURRENT_DATE - INTERVAL '27 days'), 'Client Dupont', v_user_id, v_cat_freelance, v_compte_eur),
    -- Depenses
    (gen_random_uuid(), 750.00, 'Loyer mars', 'DEPENSE', (CURRENT_DATE - INTERVAL '36 days'), NULL, v_user_id, v_cat_logement, v_compte_eur),
    (gen_random_uuid(), 85.50, 'Carrefour', 'DEPENSE', (CURRENT_DATE - INTERVAL '34 days'), NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 42.00, 'Essence', 'DEPENSE', (CURRENT_DATE - INTERVAL '32 days'), NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 120.00, 'Medecin + pharmacie', 'DEPENSE', (CURRENT_DATE - INTERVAL '30 days'), NULL, v_user_id, v_cat_sante, v_compte_eur),
    (gen_random_uuid(), 35.90, 'Lidl', 'DEPENSE', (CURRENT_DATE - INTERVAL '28 days'), NULL, v_user_id, v_cat_courses, v_compte_eur),
    (gen_random_uuid(), 28.50, 'Sushi Shop', 'DEPENSE', (CURRENT_DATE - INTERVAL '25 days'), NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 65.00, 'Cinema + bowling', 'DEPENSE', (CURRENT_DATE - INTERVAL '22 days'), NULL, v_user_id, v_cat_loisirs, v_compte_eur),
    (gen_random_uuid(), 92.30, 'Courses semaine', 'DEPENSE', (CURRENT_DATE - INTERVAL '20 days'), NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 15.00, 'Uber', 'DEPENSE', (CURRENT_DATE - INTERVAL '18 days'), NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 48.00, 'Restaurant italien', 'DEPENSE', (CURRENT_DATE - INTERVAL '15 days'), NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 110.00, 'Courses Auchan', 'DEPENSE', (CURRENT_DATE - INTERVAL '12 days'), NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 55.00, 'Plein essence', 'DEPENSE', (CURRENT_DATE - INTERVAL '9 days'), NULL, v_user_id, v_cat_transport, v_compte_eur);

    -- TRANSACTIONS EUR — Fevrier 2026
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 2800.00, 'Salaire Fevrier', 'RECETTE', (CURRENT_DATE - INTERVAL '64 days'), NULL, v_user_id, v_cat_salaire, v_compte_eur),
    (gen_random_uuid(), 750.00, 'Loyer fevrier', 'DEPENSE', (CURRENT_DATE - INTERVAL '64 days'), NULL, v_user_id, v_cat_logement, v_compte_eur),
    (gen_random_uuid(), 95.00, 'Courses Carrefour', 'DEPENSE', (CURRENT_DATE - INTERVAL '61 days'), NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 38.00, 'Essence', 'DEPENSE', (CURRENT_DATE - INTERVAL '57 days'), NULL, v_user_id, v_cat_transport, v_compte_eur),
    (gen_random_uuid(), 22.00, 'Kebab + tacos', 'DEPENSE', (CURRENT_DATE - INTERVAL '55 days'), NULL, v_user_id, v_cat_restaurant, v_compte_eur),
    (gen_random_uuid(), 180.00, 'Dentiste', 'DEPENSE', (CURRENT_DATE - INTERVAL '51 days'), NULL, v_user_id, v_cat_sante, v_compte_eur),
    (gen_random_uuid(), 73.50, 'Courses semaine', 'DEPENSE', (CURRENT_DATE - INTERVAL '47 days'), NULL, v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(), 40.00, 'Jeux video', 'DEPENSE', (CURRENT_DATE - INTERVAL '44 days'), NULL, v_user_id, v_cat_loisirs, v_compte_eur),
    (gen_random_uuid(), 52.00, 'Plein essence', 'DEPENSE', (CURRENT_DATE - INTERVAL '40 days'), NULL, v_user_id, v_cat_transport, v_compte_eur);

    -- TRANSACTIONS EUR — Avril 2026 (1er au 3)
    -- Deplace depuis V24__seed_april_2026.sql (devenue no-op) pour garantir
    -- l'idempotence sur reset DB dev.
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 2800.00, 'Salaire Avril',     'RECETTE', (CURRENT_DATE - INTERVAL '5 days'), NULL,               v_user_id, v_cat_salaire,      v_compte_eur),
    (gen_random_uuid(),  750.00, 'Loyer avril',       'DEPENSE', (CURRENT_DATE - INTERVAL '5 days'), NULL,               v_user_id, v_cat_logement,     v_compte_eur),
    (gen_random_uuid(),   29.99, 'Orange Fibre',      'DEPENSE', (CURRENT_DATE - INTERVAL '5 days'), 'Prelevement auto', v_user_id, v_cat_abonnement,   v_compte_eur),
    (gen_random_uuid(),   67.40, 'Carrefour Market',  'DEPENSE', (CURRENT_DATE - INTERVAL '4 days'), NULL,               v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(),    1.90, 'Ticket metro',      'DEPENSE', (CURRENT_DATE - INTERVAL '4 days'), NULL,               v_user_id, v_cat_transport,    v_compte_eur),
    (gen_random_uuid(),   12.50, 'Boulangerie',       'DEPENSE', (CURRENT_DATE - INTERVAL '4 days'), NULL,               v_user_id, v_cat_alimentation, v_compte_eur),
    (gen_random_uuid(),   14.90, 'Dejeuner kebab',    'DEPENSE', (CURRENT_DATE - INTERVAL '3 days'), NULL,               v_user_id, v_cat_restaurant,   v_compte_eur),
    (gen_random_uuid(),   43.20, 'Lidl',              'DEPENSE', (CURRENT_DATE - INTERVAL '3 days'), NULL,               v_user_id, v_cat_courses,      v_compte_eur),
    (gen_random_uuid(),   48.00, 'Plein essence',     'DEPENSE', (CURRENT_DATE - INTERVAL '3 days'), NULL,               v_user_id, v_cat_transport,    v_compte_eur);

    -- ===========================================================
    -- TRANSACTIONS XOF — Mars 2026
    -- ===========================================================
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 350000, 'Virement famille', 'RECETTE', (CURRENT_DATE - INTERVAL '35 days'), NULL, v_user_id, v_cat_salaire, v_compte_xof),
    (gen_random_uuid(), 45000, 'Marche Assigame', 'DEPENSE', (CURRENT_DATE - INTERVAL '33 days'), NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(), 15000, 'Taxi-moto', 'DEPENSE', (CURRENT_DATE - INTERVAL '31 days'), NULL, v_user_id, v_cat_transport, v_compte_xof),
    (gen_random_uuid(), 75000, 'Loyer local', 'DEPENSE', (CURRENT_DATE - INTERVAL '36 days'), NULL, v_user_id, v_cat_logement, v_compte_xof),
    (gen_random_uuid(), 8500, 'Pharmacie', 'DEPENSE', (CURRENT_DATE - INTERVAL '26 days'), NULL, v_user_id, v_cat_sante, v_compte_xof),
    (gen_random_uuid(), 25000, 'Marche Hedzranawoe', 'DEPENSE', (CURRENT_DATE - INTERVAL '22 days'), NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(), 12000, 'Maquis', 'DEPENSE', (CURRENT_DATE - INTERVAL '19 days'), NULL, v_user_id, v_cat_restaurant, v_compte_xof),
    (gen_random_uuid(), 35000, 'Courses semaine', 'DEPENSE', (CURRENT_DATE - INTERVAL '15 days'), NULL, v_user_id, v_cat_courses, v_compte_xof),
    (gen_random_uuid(), 5000, 'Zem', 'DEPENSE', (CURRENT_DATE - INTERVAL '11 days'), NULL, v_user_id, v_cat_transport, v_compte_xof);

    -- TRANSACTIONS XOF — Avril 2026 (1er au 3)
    -- Deplace depuis V24__seed_april_2026.sql
    INSERT INTO transactions (id, montant, libelle, type, date, note, user_id, category_id, account_id) VALUES
    (gen_random_uuid(), 75000, 'Loyer local avril', 'DEPENSE', (CURRENT_DATE - INTERVAL '5 days'), NULL, v_user_id, v_cat_logement,     v_compte_xof),
    (gen_random_uuid(), 18500, 'Marche Assigame',   'DEPENSE', (CURRENT_DATE - INTERVAL '4 days'), NULL, v_user_id, v_cat_alimentation, v_compte_xof),
    (gen_random_uuid(),  3500, 'Zem trajet',        'DEPENSE', (CURRENT_DATE - INTERVAL '4 days'), NULL, v_user_id, v_cat_transport,    v_compte_xof),
    (gen_random_uuid(), 12000, 'Courses marche',    'DEPENSE', (CURRENT_DATE - INTERVAL '3 days'), NULL, v_user_id, v_cat_courses,      v_compte_xof),
    (gen_random_uuid(),  4500, 'Maquis midi',       'DEPENSE', (CURRENT_DATE - INTERVAL '3 days'), NULL, v_user_id, v_cat_restaurant,   v_compte_xof);

    -- ===========================================================
    -- ABONNEMENTS
    -- ===========================================================
    DELETE FROM subscriptions WHERE user_id = v_user_id AND nom IN ('Netflix', 'Spotify', 'Canal+', 'Orange Fibre');

    INSERT INTO subscriptions (id, nom, montant, frequence, date_debut, actif, user_id, category_id, account_id, currency) VALUES
    (gen_random_uuid(), 'Netflix', 13.49, 'MENSUEL', (CURRENT_DATE - INTERVAL '309 days'), true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Spotify', 10.99, 'MENSUEL', (CURRENT_DATE - INTERVAL '446 days'), true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Canal+', 25.99, 'MENSUEL', (CURRENT_DATE - INTERVAL '217 days'), true, v_user_id, v_cat_abonnement, v_compte_xof, 'XOF'),
    (gen_random_uuid(), 'Orange Fibre', 29.99, 'MENSUEL', (CURRENT_DATE - INTERVAL '392 days'), true, v_user_id, v_cat_abonnement, v_compte_eur, 'EUR');

    -- ===========================================================
    -- DETTES
    -- ===========================================================
    DELETE FROM debts WHERE user_id = v_user_id AND personne IN ('Kofi', 'Marie', 'Papa');

    INSERT INTO debts (id, personne, montant, sens, date, due_date, rembourse, user_id, category_id, account_id, currency) VALUES
    (gen_random_uuid(), 'Kofi', 150000, 'PRET', (CURRENT_DATE - INTERVAL '50 days'), (CURRENT_DATE + INTERVAL '22 days'), false, v_user_id, v_cat_dette, v_compte_xof, 'XOF'),
    (gen_random_uuid(), 'Marie', 200.00, 'EMPRUNT', (CURRENT_DATE - INTERVAL '36 days'), (CURRENT_DATE - INTERVAL '3 days'), false, v_user_id, v_cat_dette, v_compte_eur, 'EUR'),
    (gen_random_uuid(), 'Papa', 500.00, 'EMPRUNT', (CURRENT_DATE - INTERVAL '86 days'), (CURRENT_DATE - INTERVAL '27 days'), true, v_user_id, v_cat_dette, v_compte_eur, 'EUR');

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
    (gen_random_uuid(), 750.00, 'Loyer', 'DEPENSE', (CURRENT_DATE - INTERVAL '36 days'), v_user_id, v_cat_logement, v_compte_eur, true, 'MENSUEL', (CURRENT_DATE + INTERVAL '5 days'), true),
    (gen_random_uuid(), 45.00, 'Assurance auto', 'DEPENSE', (CURRENT_DATE - INTERVAL '22 days'), v_user_id, v_cat_transport, v_compte_eur, true, 'MENSUEL', (CURRENT_DATE + INTERVAL '12 days'), true);

    -- ===========================================================
    -- AUTRES UTILISATEURS (KKS-354)
    -- ===========================================================
    -- L'application est multi-utilisateurs : invitations, roles, isolation
    -- stricte des donnees. Un seed mono-utilisateur ne permet ni de le
    -- montrer, ni de verifier que l'isolation tient reellement.
    --
    -- Volume volontairement plus faible que pour dev@local.test : ces comptes
    -- servent a peupler l'ecran d'administration et a rendre l'isolation
    -- observable, pas a etre explores.
    --
    -- Meme mot de passe que le compte principal (dev123), meme hash BCrypt.
    -- NE JAMAIS utiliser ces identifiants en production.

    INSERT INTO users (id, email, password, name, is_admin, created_at)
    VALUES
        (gen_random_uuid(), 'admin@local.test',
         '$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq',
         'Amina Diallo', true, NOW() - INTERVAL '90 days'),
        (gen_random_uuid(), 'invite@local.test',
         '$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq',
         'Thomas Berger', false, NOW() - INTERVAL '12 days')
    ON CONFLICT (email) DO NOTHING;

    SELECT id INTO v_user_admin FROM users WHERE email = 'admin@local.test';
    SELECT id INTO v_user_invite FROM users WHERE email = 'invite@local.test';

    -- Chaque utilisateur a ses propres categories et son propre compte :
    -- rien n'est partage, c'est le principe II de la constitution.
    FOREACH v_other IN ARRAY ARRAY[v_user_admin, v_user_invite] LOOP

        INSERT INTO user_preferences (id, user_id, enabled_features, nav_order, currencies, timezone, text_scale)
        VALUES (gen_random_uuid(), v_other, 'SUBSCRIPTIONS,DEBTS', 'SUBSCRIPTIONS,DEBTS', 'EUR', 'Europe/Paris', 'MEDIUM')
        ON CONFLICT (user_id) DO NOTHING;

        INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
        SELECT gen_random_uuid(), c.nom, c.icone, c.couleur, c.is_system, v_other
        FROM (VALUES
            ('Abonnement', '🔄', '#6366f1', true),
            ('Dette',      '💰', '#ef4444', true),
            ('Virement',   '🔄', '#8b5cf6', true),
            ('Courses',    '🧺', '#14b8a6', false),
            ('Salaire',    '💼', '#10b981', false)
        ) AS c(nom, icone, couleur, is_system)
        WHERE NOT EXISTS (
            SELECT 1 FROM categories x WHERE LOWER(x.nom) = LOWER(c.nom) AND x.user_id = v_other
        );

        DELETE FROM transactions WHERE user_id = v_other;
        DELETE FROM accounts WHERE user_id = v_other;

        v_compte_autre := gen_random_uuid();
        INSERT INTO accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, currency, bank_code, user_id)
        VALUES (v_compte_autre, 'Compte Principal', 'COURANT', 1200.00, '🏦', '#3b82f6', true, true, 'EUR', 'OTHER', v_other);

        SELECT id INTO v_cat_autre_salaire FROM categories WHERE nom = 'Salaire' AND user_id = v_other;
        SELECT id INTO v_cat_autre_courses FROM categories WHERE nom = 'Courses' AND user_id = v_other;

        INSERT INTO transactions (id, montant, libelle, type, date, user_id, category_id, account_id) VALUES
            (gen_random_uuid(), 2100.00, 'Salaire', 'RECETTE', (CURRENT_DATE - INTERVAL '5 days'), v_other, v_cat_autre_salaire, v_compte_autre),
            (gen_random_uuid(),   78.40, 'Courses',  'DEPENSE', (CURRENT_DATE - INTERVAL '25 days'), v_other, v_cat_autre_courses, v_compte_autre),
            (gen_random_uuid(), 2100.00, 'Salaire', 'RECETTE', (CURRENT_DATE -  INTERVAL '3 days'), v_other, v_cat_autre_salaire, v_compte_autre),
            (gen_random_uuid(),   61.20, 'Courses',  'DEPENSE', (CURRENT_DATE -  INTERVAL '2 days'), v_other, v_cat_autre_courses, v_compte_autre);
    END LOOP;

    RAISE NOTICE 'Dev seed OK — user: %, EUR: %, XOF: %', v_user_id, v_compte_eur, v_compte_xof;
    RAISE NOTICE 'Autres utilisateurs — admin: %, invite: %', v_user_admin, v_user_invite;
END $$;
