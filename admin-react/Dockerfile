# Build the React admin, serve the static bundle with nginx.
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci 2>/dev/null || npm install
COPY nginx.conf /app/nginx.conf
COPY src ./src
COPY index.html vite.config.js ./
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
