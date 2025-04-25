FROM node:slim

WORKDIR /nodeapp

# Copy package files first for better caching
COPY nodeapp/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY nodeapp/ .

# Start the application
CMD ["node", "app.js"]
