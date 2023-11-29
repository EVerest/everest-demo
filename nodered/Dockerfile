FROM nodered/node-red:2.2.3
RUN npm install node-red-dashboard
RUN npm install node-red-contrib-ui-actions
RUN npm install node-red-node-ui-table
RUN npm install node-red-contrib-ui-level

COPY config /config

LABEL org.opencontainers.image.source=https://github.com/us-joet/everest-demo
