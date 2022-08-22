# development stage
FROM node:16 AS development
WORKDIR /usr/src/app
RUN mkdir -p /usr/src/app/config
COPY package.json /usr/src/app/
COPY yarn.lock /usr/src/app/
#copy superstatic.json to config folder used by superstatic server
COPY server/superstatic.json /usr/src/app/config/
RUN yarn install --frozen-lockfile
COPY . /usr/src/app/
RUN yarn run build

# build stage
FROM development AS build
# install production deps
RUN rm -rf node_modules && yarn install --frozen-lockfile --production

# Package stage
FROM node:16-alpine
RUN apk add dumb-init
ENV NODE_ENV production

RUN mkdir -p /usr/src/app/config
RUN mkdir -p /usr/src/app/dist
RUN chown node /usr/src/app

USER node
WORKDIR /usr/src/app

#copy package json
COPY --chown=node:node package.json /usr/src/app/
#copy production node_modules
COPY --chown=node:node --from=build /usr/src/app/node_modules /usr/src/app/node_modules
#copy superstatic.json to config folder used by superstatic server
COPY --chown=node:node --from=build /usr/src/app/config/superstatic.json /usr/src/app/config/
# copy generated static files to work directory
COPY --chown=node:node --from=build /usr/src/app/dist/ /usr/src/app/dist/

EXPOSE 1339
CMD ["dumb-init", "node", "dist/server.js"]
