FROM node:latest
WORKDIR /app-node
COPY app-exemplo .
RUN npm install
ENTRYPOINT npm start