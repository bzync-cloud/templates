FROM node:24-alpine

RUN apk add --no-cache python3 make g++

WORKDIR /home/node
COPY . .
RUN npm install --omit=dev && \
    mkdir -p .n8n && \
    chown -R node:node /home/node

USER node

VOLUME ["/home/node/.n8n"]
EXPOSE 5678

CMD ["npm", "start"]
