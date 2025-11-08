FROM node:20-alpine

# Create app dir
WORKDIR /usr/src/app

# Copy package* and install
COPY package.json ./
RUN npm install --omit=dev

# Copy app sources
COPY . .

# Expose port
EXPOSE 3000

CMD ["node", "app.js"]

