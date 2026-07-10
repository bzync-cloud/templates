FROM node:24-bookworm-slim

WORKDIR /home/node
COPY package.json ./
RUN npm install --omit=dev && \
    mkdir -p .openclaw/workspace .config/openclaw && \
    chown -R node:node /home/node

USER node

VOLUME ["/home/node/.openclaw", "/home/node/.config/openclaw"]
EXPOSE 18789

CMD ["npm", "start"]
