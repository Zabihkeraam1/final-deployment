# Dockerfile
FROM node:18-alpine

WORKDIR /app
COPY Backend/package*.json ./
RUN npm install --production
COPY Backend/ .

EXPOSE 8080
CMD ["node", "server.js"]
