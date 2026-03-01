import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

interface SettingsSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  route: string;
  status: 'active' | 'placeholder';
}

const SECTIONS: SettingsSection[] = [
  { id: 'accounts', title: 'Comptes bancaires', description: 'Gérer mes comptes', icon: '🏦', route: 'accounts', status: 'active' },
  { id: 'categories', title: 'Catégories', description: 'Gérer mes catégories', icon: '🏷️', route: 'categories', status: 'active' },
  { id: 'budget', title: 'Budget', description: 'Définir mes budgets', icon: '📊', route: 'budget', status: 'placeholder' },
  { id: 'notifications', title: 'Notifications', description: 'Configurer les alertes', icon: '🔔', route: 'notifications', status: 'placeholder' },
  { id: 'profile', title: 'Profil', description: 'Mes informations', icon: '👤', route: 'profile', status: 'active' },
  { id: 'features', title: 'Fonctionnalités', description: 'Activer/désactiver les modules', icon: '⚡', route: 'features', status: 'active' },
  { id: 'appearance', title: 'Apparence', description: 'Thème et affichage', icon: '🎨', route: 'appearance', status: 'active' },
  { id: 'data', title: 'Données', description: 'Serveur et maintenance', icon: '💾', route: 'data', status: 'active' },
  { id: 'about', title: 'À propos', description: "Informations sur l'app", icon: 'ℹ️', route: 'about', status: 'active' },
];

@Component({
  selector: 'app-settings',
  imports: [RouterLink],
  templateUrl: './settings.html',
  styleUrl: './settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Settings {
  readonly sections = SECTIONS;
}
