FROM node:alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY index.html ./
COPY server.js ./

EXPOSE 8081

CMD ["node", "server.js"]
