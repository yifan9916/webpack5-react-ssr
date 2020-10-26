FROM node:14-alpine as base

LABEL org.opencontainers.image.authors=yifan.9916@gmail.com
LABEL org.opencontainers.image.title="Webpack5 React SSR"
LABEL org.opencontainers.image.licenses=ISC
LABEL yifan.nodeversion=$NODE_VERSION

EXPOSE 3000 3001
ENV NODE_ENV=production \
  PORT=3000 \
  PATH=/node/node_modules/.bin:$PATH
RUN apk add --no-cache tini
WORKDIR /node
COPY package*.json ./
RUN yarn config list \
  && yarn --production \
  && yarn cache clean --force
ENTRYPOINT ["/sbin/tini", "--"]

FROM base as dev
WORKDIR /node/app
ENV NODE_ENV=development
RUN yarn config list \
  && yarn \
  && yarn cache clean --force
CMD ["yarn", "start"]

FROM dev as test
COPY . .
RUN yarn audit || true
RUN yarn fmt \
  && yarn lint \
  && yarn test

FROM test as source
ENV NODE_ENV=production
RUN yarn build

FROM base as prod
WORKDIR /node/app
COPY healthcheck.js ./
COPY --from=source /node/app/dist .
COPY --from=source /node/app/public ./public
HEALTHCHECK --interval=1m --timeout=3s \
  CMD node healthcheck.js || exit 1
USER node
CMD ["node", "server.js"]
