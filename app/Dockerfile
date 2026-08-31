# ---- Stage build ----
# Epingle sur l'architecture du runner : le bundle Angular produit est statique
# et independant de l'architecture cible (KKS-308).
FROM --platform=$BUILDPLATFORM node:22-alpine AS build
WORKDIR /app

# Cache des dependances npm
COPY package.json package-lock.json ./
RUN npm ci

# Build production Angular
COPY . .
RUN npx ng build --configuration production

# ---- Stage runtime ----
FROM nginx:alpine

COPY --from=build /app/dist/k-budget-app/browser/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
