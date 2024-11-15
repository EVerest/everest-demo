FROM nodered/node-red:4.0.5
RUN npm install node-red-dashboard
RUN npm install node-red-contrib-ui-actions
RUN npm install node-red-node-ui-table
RUN npm install node-red-contrib-ui-level

COPY --chown=node-red:root config /config

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
