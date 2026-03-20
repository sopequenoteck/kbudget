import { ChangeDetectionStrategy, Component, computed } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorBank,
  phosphorTag,
  phosphorBell,
  phosphorUser,
  phosphorToggleRight,
  phosphorPalette,
  phosphorDatabase,
  phosphorInfo,
  phosphorCurrencyCircleDollar,
  phosphorLock,
  phosphorUploadSimple,
} from '@ng-icons/phosphor-icons/regular';

export type SettingsGroup = 'general' | 'management' | 'other';

export const GROUP_LABELS: Record<SettingsGroup, string> = {
  general: 'Général',
  management: 'Gestion',
  other: 'Autre',
};

interface SettingsSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  iconColor: string;
  route: string;
  status: 'active' | 'placeholder';
  group: SettingsGroup;
}

const SECTIONS: SettingsSection[] = [
  {
    id: 'profile',
    title: 'Profil',
    description: 'Nom, email, devise',
    icon: 'phosphorUser',
    iconColor: '#3b82f6',
    route: 'profile',
    status: 'active',
    group: 'general',
  },
  {
    id: 'features',
    title: 'Fonctionnalités & Navigation',
    description: 'Modules et ordre de navigation',
    icon: 'phosphorToggleRight',
    iconColor: '#22c55e',
    route: 'features',
    status: 'active',
    group: 'general',
  },
  {
    id: 'appearance',
    title: 'Apparence',
    description: 'Thème, taille texte',
    icon: 'phosphorPalette',
    iconColor: '#a855f7',
    route: 'appearance',
    status: 'active',
    group: 'general',
  },
  {
    id: 'notifications',
    title: 'Notifications',
    description: "Types d'alertes et fuseau horaire",
    icon: 'phosphorBell',
    iconColor: '#f59e0b',
    route: 'notifications',
    status: 'active',
    group: 'general',
  },
  {
    id: 'accounts',
    title: 'Comptes',
    description: 'Gérer les comptes',
    icon: 'phosphorBank',
    iconColor: '#14b8a6',
    route: 'accounts',
    status: 'active',
    group: 'management',
  },
  {
    id: 'categories',
    title: 'Catégories',
    description: 'Gérer les catégories',
    icon: 'phosphorTag',
    iconColor: '#f97316',
    route: 'categories',
    status: 'active',
    group: 'management',
  },
  {
    id: 'currencies',
    title: 'Devises & Taux',
    description: 'Devises et taux de conversion',
    icon: 'phosphorCurrencyCircleDollar',
    iconColor: '#f59e0b',
    route: 'currencies',
    status: 'active',
    group: 'management',
  },
  {
    id: 'data',
    title: 'Données',
    description: 'Serveur et maintenance',
    icon: 'phosphorDatabase',
    iconColor: '#6366f1',
    route: 'data',
    status: 'active',
    group: 'management',
  },
  {
    id: 'import',
    title: 'Import',
    description: 'Importer des relevés CSV',
    icon: 'phosphorUploadSimple',
    iconColor: '#10b981',
    route: 'import',
    status: 'active',
    group: 'management',
  },
  {
    id: 'security',
    title: 'Sécurité',
    description: 'Verrouillage, biométrie',
    icon: 'phosphorLock',
    iconColor: '#ef4444',
    route: 'security',
    status: 'placeholder',
    group: 'other',
  },
  {
    id: 'about',
    title: 'À propos',
    description: 'Version, informations',
    icon: 'phosphorInfo',
    iconColor: '#6b7280',
    route: 'about',
    status: 'active',
    group: 'other',
  },
];

@Component({
  selector: 'app-settings',
  imports: [RouterLink, NgIcon],
  providers: [
    provideIcons({
      phosphorBank,
      phosphorTag,
      phosphorBell,
      phosphorUser,
      phosphorToggleRight,
      phosphorPalette,
      phosphorDatabase,
      phosphorInfo,
      phosphorCurrencyCircleDollar,
      phosphorLock,
      phosphorUploadSimple,
    }),
  ],
  templateUrl: './settings.html',
  styleUrl: './settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Settings {
  readonly groupLabels = GROUP_LABELS;
  readonly groups: SettingsGroup[] = ['general', 'management', 'other'];

  readonly groupedSections = computed(() => {
    const result: Record<SettingsGroup, SettingsSection[]> = {
      general: [],
      management: [],
      other: [],
    };
    for (const section of SECTIONS) {
      result[section.group].push(section);
    }
    return result;
  });
}
