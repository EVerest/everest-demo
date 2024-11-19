FROM nodered/node-red:4.0.5

# Install Node Dependancies
RUN npm install node-red-dashboard
RUN npm install node-red-contrib-ui-actions
RUN npm install node-red-node-ui-table
RUN npm install node-red-contrib-ui-level

# Setup Python Virtual Environment for Powercurve Generation
RUN python3 -m venv /usr/src/node-red/python_environments/everest
RUN /usr/src/node-red/python_environments/everest/bin/python3 -m ensurepip
RUN /usr/src/node-red/python_environments/everest/bin/pip3 install numpy control
COPY --chown=node-red:root scripts /bin/scripts/

#Copy over node-red flows
COPY --chown=node-red:root config /config

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
