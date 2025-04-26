FROM node:slim
WORKDIR /nodeapp
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "app.js"]
