export interface Product {
  id: string;
  nom: string;
  description: string | null;
  icone: string | null;
  imageUrl: string | null;
  prixAchat: number;
  prixVente: number;
  stock: number;
  totalVendu: number;
  actif: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProductRequest {
  nom: string;
  description?: string;
  icone?: string;
  imageUrl?: string;
  prixAchat: number;
  prixVente: number;
  stock: number;
}

export interface ProductUpdateRequest extends ProductRequest {
  actif: boolean;
}

export interface RestockRequest {
  quantity: number;
}

export interface SellRequest {
  quantity: number;
}
