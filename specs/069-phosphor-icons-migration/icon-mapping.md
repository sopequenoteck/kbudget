# Icon Mapping: Migration Phosphor Icons

**Branch**: `069-phosphor-icons-migration` | **Date**: 2026-03-06

## Convention de styles

| Contexte | Taille | Style Flutter | Style Angular |
|----------|--------|---------------|---------------|
| Navigation (inactive) | 24px | `PhosphorIconsRegular.*` | `phosphorXxx` (regular) |
| Navigation (active) | 24px | `PhosphorIconsFill.*` | `phosphorXxxFill` (fill) |
| Actions (FAB, boutons) | 24px | `PhosphorIconsBold.*` | `phosphorXxxBold` (bold) |
| Inline (listes, forms) | 20px | `PhosphorIconsRegular.*` | `phosphorXxx` (regular) |
| Decoratif (badges) | 16px | `PhosphorIconsRegular.*` | `phosphorXxx` (regular) |

---

## Flutter: Material Icons -> Phosphor

### Navigation & Structure

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.home` / `Icons.home_outlined` | `PhosphorIconsFill.house` / `PhosphorIconsRegular.house` | Bottom nav |
| `Icons.receipt_long` / `Icons.receipt_long_outlined` | `PhosphorIconsFill.receipt` / `PhosphorIconsRegular.receipt` | Bottom nav |
| `Icons.autorenew` / `Icons.autorenew_outlined` | `PhosphorIconsFill.arrowsClockwise` / `PhosphorIconsRegular.arrowsClockwise` | Bottom nav (subscriptions) |
| `Icons.handshake` / `Icons.handshake_outlined` | `PhosphorIconsFill.handshake` / `PhosphorIconsRegular.handshake` | Bottom nav (debts) |
| `Icons.storefront` / `Icons.storefront_outlined` | `PhosphorIconsFill.storefront` / `PhosphorIconsRegular.storefront` | Bottom nav (shop) |

### Actions (Bold, 24px)

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.add` | `PhosphorIconsBold.plus` | FAB, add buttons |
| `Icons.close` | `PhosphorIconsBold.x` | Modal close |
| `Icons.check` | `PhosphorIconsBold.check` | Confirm/save actions |
| `Icons.delete_outline` | `PhosphorIconsBold.trash` | Delete actions |
| `Icons.refresh` | `PhosphorIconsBold.arrowClockwise` | Refresh/retry |
| `Icons.swap_horiz` | `PhosphorIconsBold.arrowsLeftRight` | Transfer |
| `Icons.edit_outlined` | `PhosphorIconsBold.pencilSimple` | Edit |

### Inline / Forms (Regular, 20px)

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.email_outlined` | `PhosphorIconsRegular.envelope` | Email field |
| `Icons.lock_outlined` | `PhosphorIconsRegular.lock` | Password field |
| `Icons.person_outlined` | `PhosphorIconsRegular.user` | Name field |
| `Icons.visibility_outlined` | `PhosphorIconsRegular.eye` | Show password |
| `Icons.visibility_off_outlined` | `PhosphorIconsRegular.eyeSlash` | Hide password |
| `Icons.calendar_today` | `PhosphorIconsRegular.calendar` | Date picker |
| `Icons.chevron_right` | `PhosphorIconsRegular.caretRight` | List arrow |
| `Icons.chevron_left` | `PhosphorIconsRegular.caretLeft` | Month nav |
| `Icons.more_vert` | `PhosphorIconsRegular.dotsThreeVertical` | More menu |
| `Icons.keyboard_arrow_down` | `PhosphorIconsRegular.caretDown` | Dropdown |
| `Icons.drag_handle` | `PhosphorIconsRegular.dotsSixVertical` | Drag handle |
| `Icons.link` | `PhosphorIconsRegular.link` | Server URL |
| `Icons.save` | `PhosphorIconsRegular.floppyDisk` | Save |
| `Icons.info_outline` | `PhosphorIconsRegular.info` | Info hint |

### Settings (Regular, 24px)

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.person` | `PhosphorIconsRegular.user` | Profile section |
| `Icons.toggle_on` | `PhosphorIconsRegular.toggleRight` | Features section |
| `Icons.palette` | `PhosphorIconsRegular.palette` | Appearance section |
| `Icons.account_balance` | `PhosphorIconsRegular.bank` | Accounts section |
| `Icons.label` | `PhosphorIconsRegular.tag` | Categories section |
| `Icons.storage` | `PhosphorIconsRegular.database` | Data section |
| `Icons.lock` | `PhosphorIconsRegular.lock` | Security section |
| `Icons.info` | `PhosphorIconsRegular.info` | About section |
| `Icons.light_mode` | `PhosphorIconsRegular.sun` | Light theme |
| `Icons.dark_mode` | `PhosphorIconsRegular.moon` | Dark theme |
| `Icons.settings_outlined` | `PhosphorIconsRegular.gear` | Settings menu |
| `Icons.logout` | `PhosphorIconsRegular.signOut` | Logout |
| `Icons.phone_android` | `PhosphorIconsRegular.deviceMobile` | Local mode |
| `Icons.cloud` / `Icons.cloud_outlined` | `PhosphorIconsRegular.cloud` | Server mode |

### Status (Regular, 20px)

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.error_outline` | `PhosphorIconsRegular.warningCircle` | Error state |
| `Icons.check_circle` | `PhosphorIconsRegular.checkCircle` | Success state |
| `Icons.wifi_find` | `PhosphorIconsRegular.wifiHigh` | Connection check |
| `Icons.verified_outlined` | `PhosphorIconsRegular.sealCheck` | Verified |

### Shop (Mixed)

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.camera_alt` | `PhosphorIconsRegular.camera` | Take photo (20px) |
| `Icons.photo_library` | `PhosphorIconsRegular.images` | Pick from gallery (20px) |
| `Icons.add_a_photo` | `PhosphorIconsRegular.cameraPlus` | Add photo (20px) |
| `Icons.add_shopping_cart` | `PhosphorIconsBold.shoppingCart` | Restock (24px action) |
| `Icons.sell` | `PhosphorIconsBold.tag` | Sell (24px action) |
| `Icons.trending_up` | `PhosphorIconsRegular.trendUp` | Revenue trend (20px) |
| `Icons.trending_down` | `PhosphorIconsRegular.trendDown` | Expense trend (20px) |

### Misc

| Material Icon | Phosphor Flutter | Contexte |
|---------------|-----------------|----------|
| `Icons.account_balance_wallet` / `Icons.account_balance_wallet_outlined` | `PhosphorIconsRegular.wallet` | Dashboard/onboarding wallet |
| `Icons.smartphone` | `PhosphorIconsRegular.deviceMobile` | Onboarding mobile |
| `Icons.fingerprint` | `PhosphorIconsRegular.fingerprint` | Biometric auth |
| `Icons.lock_outline` | `PhosphorIconsRegular.lock` | Locked feature |

---

## Angular: Emojis -> Phosphor

### Navigation (shell, bottom-nav)

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| (home icon) | `phosphorHouse` / `phosphorHouseFill` | `regular` / `fill` | Home nav |
| (money icon) | `phosphorCurrencyDollar` / `phosphorCurrencyDollarFill` | `regular` / `fill` | Transactions nav |
| (gear) | `phosphorGear` | `regular` | Settings menu |
| (door) | `phosphorSignOut` | `regular` | Logout menu |

### FAB Actions (Bold, 24px)

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| + | `phosphorPlusBold` | `bold` | FAB main |
| (money) | `phosphorCurrencyDollarBold` | `bold` | New transaction |
| (arrows) | `phosphorArrowsClockwiseBold` | `bold` | New subscription |
| (handshake) | `phosphorHandshakeBold` | `bold` | New debt |
| (transfer) | `phosphorArrowsLeftRightBold` | `bold` | New transfer |
| (package) | `phosphorPackageBold` | `bold` | New product |
| (sell) | `phosphorTagBold` | `bold` | New sale |

### Settings (Regular, 24px)

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| (bank) | `phosphorBank` | `regular` | Accounts |
| (tag) | `phosphorTag` | `regular` | Categories |
| (chart) | `phosphorChartBar` | `regular` | Budget |
| (bell) | `phosphorBell` | `regular` | Notifications |
| (person) | `phosphorUser` | `regular` | Profile |
| (lightning) | `phosphorLightning` | `regular` | Features |
| (palette) | `phosphorPalette` | `regular` | Appearance |
| (disk) | `phosphorFloppyDisk` | `regular` | Data |
| (info) | `phosphorInfo` | `regular` | About |

### Features (preference.model.ts)

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| (arrows) | `phosphorArrowsClockwise` / `phosphorArrowsClockwiseFill` | `regular` / `fill` | Subscriptions feature |
| (handshake) | `phosphorHandshake` / `phosphorHandshakeFill` | `regular` / `fill` | Debts feature |
| (shop) | `phosphorStorefront` / `phosphorStorefrontFill` | `regular` / `fill` | Shop feature |

### Shop

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| (shop) | `phosphorStorefront` | `regular` | Empty state |
| (package) | `phosphorPackage` | `regular` | Default product icon |
| (tag) | `phosphorTag` | `regular` | Sell button |
| (cart) | `phosphorShoppingCart` | `regular` | Restock button |
| (back) | `phosphorArrowLeft` | `regular` | Back navigation |
| (edit) | `phosphorPencilSimple` | `regular` | Edit button |
| (trend up) | `phosphorTrendUp` | `regular` | Revenue |
| (trend down) | `phosphorTrendDown` | `regular` | Expense |

### Settings actions

| Emoji | Phosphor Angular | Import path | Contexte |
|-------|-----------------|-------------|----------|
| (star) | `phosphorStar` | `regular` | Set as default |
| (edit) | `phosphorPencilSimple` | `regular` | Edit |
| (trash) | `phosphorTrash` | `regular` | Delete |
| (drag) | `phosphorDotsSixVertical` | `regular` | Drag handle |
| (home) | `phosphorHouse` | `regular` | Home (locked nav) |
| (money) | `phosphorCurrencyDollar` | `regular` | Transactions (locked nav) |

---

## Emojis UTILISATEUR (NE PAS MODIFIER)

Les emojis suivants sont des donnees utilisateur, PAS des icones systeme :
- `account.icone` — emoji choisi par l'user pour ses comptes
- `category.icone` / `cat.icone` — emoji choisi par l'user pour ses categories
- `product.icone` — emoji choisi par l'user pour ses produits
- `subscription.category?.icone` — emoji de categorie (donnee user)
- Default emojis dans `account-form.ts` — valeurs par defaut des comptes
- `product.imageUrl` — images de produits (FR-005)
