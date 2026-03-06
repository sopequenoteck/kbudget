import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorBank,
  phosphorTag,
  phosphorChartBar,
  phosphorBell,
  phosphorUser,
  phosphorLightning,
  phosphorPalette,
  phosphorFloppyDisk,
  phosphorInfo,
  phosphorCurrencyCircleDollar,
} from '@ng-icons/phosphor-icons/regular';

interface SettingsSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  route: string;
  status: 'active' | 'placeholder';
}

const SECTIONS: SettingsSection[] = [
  {
    id: 'accounts',
    title: 'Comptes bancaires',
    description: 'Gérer mes comptes',
    icon: 'phosphorBank',
    route: 'accounts',
    status: 'active',
  },
  {
    id: 'categories',
    title: 'Catégories',
    description: 'Gérer mes catégories',
    icon: 'phosphorTag',
    route: 'categories',
    status: 'active',
  },
  {
    id: 'budget',
    title: 'Budget',
    description: 'Définir mes budgets',
    icon: 'phosphorChartBar',
    route: 'budget',
    status: 'placeholder',
  },
  {
    id: 'notifications',
    title: 'Notifications',
    description: 'Configurer les alertes',
    icon: 'phosphorBell',
    route: 'notifications',
    status: 'placeholder',
  },
  {
    id: 'profile',
    title: 'Profil',
    description: 'Mes informations',
    icon: 'phosphorUser',
    route: 'profile',
    status: 'active',
  },
  {
    id: 'features',
    title: 'Fonctionnalités',
    description: 'Activer/désactiver les modules',
    icon: 'phosphorLightning',
    route: 'features',
    status: 'active',
  },
  {
    id: 'appearance',
    title: 'Apparence',
    description: 'Thème et affichage',
    icon: 'phosphorPalette',
    route: 'appearance',
    status: 'active',
  },
  {
    id: 'currencies',
    title: 'Devises & Taux',
    description: 'Gérer les taux de conversion',
    icon: 'phosphorCurrencyCircleDollar',
    route: 'currencies',
    status: 'active',
  },
  {
    id: 'data',
    title: 'Données',
    description: 'Serveur et maintenance',
    icon: 'phosphorFloppyDisk',
    route: 'data',
    status: 'active',
  },
  {
    id: 'about',
    title: 'À propos',
    description: "Informations sur l'app",
    icon: 'phosphorInfo',
    route: 'about',
    status: 'active',
  },
];

@Component({
  selector: 'app-settings',
  imports: [RouterLink, NgIcon],
  providers: [
    provideIcons({
      phosphorBank,
      phosphorTag,
      phosphorChartBar,
      phosphorBell,
      phosphorUser,
      phosphorLightning,
      phosphorPalette,
      phosphorFloppyDisk,
      phosphorInfo,
      phosphorCurrencyCircleDollar,
    }),
  ],
  templateUrl: './settings.html',
  styleUrl: './settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Settings {
  readonly sections = SECTIONS;
}
