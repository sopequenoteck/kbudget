export interface Category {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
  isSystem: boolean;
}

export interface CategoryRequest {
  nom: string;
  icone: string;
  couleur: string;
}
