-- =============================================================
-- K-Budget — Seed Produits Boutique
-- Mix tech, textile, produits locaux Togo
-- =============================================================

DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Recuperer le user existant
    SELECT id INTO v_user_id FROM users LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Aucun utilisateur en base.';
    END IF;

    -- ===========================================================
    -- PRODUITS BOUTIQUE (10 produits)
    -- ===========================================================
    INSERT INTO products (id, nom, description, icone, image_url, prix_achat, prix_vente, stock, total_vendu, actif, created_at, user_id) VALUES
    -- Tech / Accessoires
    (gen_random_uuid(),
     'Coque iPhone 15',
     'Coque silicone souple, anti-choc, coloris noir mat. Compatible MagSafe.',
     '📱', 'https://images.unsplash.com/photo-1601593346740-925612772716?w=400',
     3.50, 12.99, 45, 18, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Cable USB-C tresse',
     'Cable USB-C vers USB-C, 2m, charge rapide 100W, gaine nylon tressee.',
     '🔌', 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400',
     2.80, 8.99, 120, 67, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Ecouteurs Bluetooth',
     'Ecouteurs intra TWS, Bluetooth 5.3, reduction de bruit passive, autonomie 6h.',
     '🎧', 'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=400',
     8.50, 24.99, 30, 12, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Chargeur solaire 10W',
     'Panneau pliable USB, 10W, etanche IPX4. Ideal pour marche ou deplacement.',
     '☀️', 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400',
     12.00, 29.99, 15, 4, true, NOW(), v_user_id),

    -- Textile
    (gen_random_uuid(),
     'Pagne Kente',
     'Pagne traditionnel tisse main, motifs geometriques, 100% coton. 6 yards.',
     '🧵', 'https://images.unsplash.com/photo-1590735213920-68192a487bc2?w=400',
     8500, 18000, 8, 22, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'T-shirt oversize',
     'T-shirt coton bio 240g, coupe oversize unisexe, coloris ecru. Tailles S a XXL.',
     '👕', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
     6.00, 19.99, 60, 35, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Sac en raphia',
     'Sac cabas tresse a la main, raphia naturel, doublure coton. Fabrication Togo.',
     '👜', 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=400',
     4500, 12000, 20, 9, true, NOW(), v_user_id),

    -- Produits locaux / Alimentaire
    (gen_random_uuid(),
     'Beurre de karite 500g',
     'Beurre de karite brut, non raffine, production artisanale du nord Togo.',
     '🧴', 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=400',
     1500, 4500, 35, 48, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Savon noir artisanal',
     'Savon noir africain 200g, a base de cendres de cacao et huile de palme.',
     '🧼', 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=400',
     800, 2500, 50, 31, true, NOW(), v_user_id),

    (gen_random_uuid(),
     'Gari premium 5kg',
     'Gari de manioc premium, grain fin, seche au soleil. Conditionne sous vide.',
     '🌾', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
     2000, 5000, 25, 15, true, NOW(), v_user_id);

    RAISE NOTICE 'Seed produits OK — user: %', v_user_id;
END $$;
