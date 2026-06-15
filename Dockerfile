FROM node:18-slim

WORKDIR /app

# Copy package files first -- layer caching!
COPY package*.json yarn.lock ./

#Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY src/ ./src/

EXPOSE 3333

CMD ["yarn", "dev"]
