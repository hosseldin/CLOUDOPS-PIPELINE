# Build stage
FROM node:12 AS builder
WORKDIR /app
COPY nodeapp/package*.json ./
RUN npm install
COPY nodeapp ./

# Production stage
FROM node:12-slim
WORKDIR /app
COPY --from=builder /app ./
USER node
CMD ["node", "app.js"]