# Quick EVerest demo (including potential cloud option!)

## SETUP: get access to docker

- If you are a developer, you might already have docker installed on your laptop
    - Check that the terminal has access to `docker` and `docker compose`
- If not, you can get a docker-enabled instance in the cloud using play-with-docker (PWD)
    https://labs.play-with-docker.com/
    ⚠️  This is a free cloud service, so access may be intermittent. You may not be able to log in, or may run out of space while downloading images even if you login. If this happens, please try again later. When it does work, it works well ⚠️
    - Create a docker account at https://hub.docker.com/signup/ (if you do not already have one)
    - Log in with the account at https://labs.play-with-docker.com/
    - Add a new instance
    - Check that the terminal has access to `docker` and `docker compose`

# EV <-> Charge station demos

## STEP 1: Run the demo
- Copy and paste the command for the demo you want to see:
    - simple AC charging station: `curl -o docker-compose.yml https://raw.githubusercontent.com/shankari/everest-demo/main/docker-compose.yml && docker compose -p everest up`
    - two EVSE charging (**basic charging does not seem to work**): `curl -o docker-compose.yml https://raw.githubusercontent.com/shankari/everest-demo/main/docker-compose.two-evse.yml && docker compose -p everest-two-evse up`
    - energy management: `curl -o docker-compose.yml https://raw.githubusercontent.com/shankari/everest-demo/main/docker-compose.two-evse.yml && docker compose -p everest-em up`

## STEP 2: Interact with the demo
- Open the `nodered` flows to understand the module flows
    - On your laptop, go to http://127.0.0.1:1880
    - On PWD, click on the "open port" button and type in 1880
      - allow brower popups if requested, or try opening twice

- Open the demo UI
    - On your laptop, append `/ui` to the URL above
    - On PWD, replace the end of the URL, starting with the hash (e.g. `#flow/9aafbf849d4d6e12)` with `/ui`

| Nodered flows | Demo UI | Including simulated error |
 |-------|--------|------|
 | ![nodered flows](img/node-red-example.png) | ![demo UI](img/charging-ui.png) | ![including simulated error](img/including-simulated-error.png) |
 

## STEP 3: See the list of modules loaded and the messages transferred between modules
![Simple AC charging station log screenshot](img/simple_ac_charging_station.png)

## TEARDOWN: Clean up after the demo
- Kill the demo process
- Delete files and containers
  - On your laptop: `docker compose -p everest down && rm docker-compose.yml`
  - On PWD: "Close session"

# EV <-> Charge station demos

EVerest does not include an implementation of the charging network-side of
OCPP. Instead they integrate with another open-source project called steve.
steve provides an implementation of charging network software, and has its on
database of users, chargeboxes, sessions etc.

⚠️  Given these additional resources needed, I would suggest running this only
locally. It requires too much time and resources for PWD ⚠️

steve has 303 forks and 544 stars in spite of the limitations below, which
highlights the need for such solutions.

- It is GPL (not even AGPL), which means that, to the best of my knowledge, the source code/libraries cannot be incorporated into non-GPL (commercial) products
- It only supports OCPP 1.6 so far, I have not evaluated the roadmap for OCPP 2.0.1 support
- It has a somewhat convoluted process in which the database needs to be running *during compile* for setup.
    - So the packaged container only includes the source; when the demo is run, we compile the source code and create the tables
    - per the maintainers (in 2020), "In reality, most people run SteVe to drive 1-2
      charge points as an appliance on a raspberry pi directly attached with
    database & co all local (a few more use a single VM/vServer)."
        https://github.com/steve-community/steve/issues/320
    - So this demo will take ~ 5 minutes to run. Get yourself a cup of your favorite beverage while waiting...
-  ⚠️  The integration doesn't actually appear to work ⚠️
    - if you now try to plug in a car using the EVSE demo UI

<details>
<summary>we get some promising-looking messages on the server side</summary>

    ```
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:15:05,608 de.rwth.idsg.steve.ocpp.ws.WebSocketLogger (qtp247162961-36) - [chargeBoxId=cp001, sessionId=3df7f3bc-e076-d275-090f-f2a6eb9d02ac] Received: [2,"ab6930f6-bf8d-477d-9c1e-d9befb11e239","DataTransfer",{"data":"{\"certificateType\":\"V2GCertificate\",\"csr\":\"-----BEGIN CERTIFICATE REQUEST-----\\nMIIBKjCB0QIBADBDMQswCQYDVQQGEwJERTEPMA0GA1UECgwGUGlvbml4MQ4wDAYD\\nVQQDDAVjcDAwMTETMBEGCgmSJomT8ixkARkWA0NQTzBZMBMGByqGSM49AgEGCCqG\\nSM49AwEHA0IABA1ax+CTmpQuDa46+uPqWvSq0Eh0Jl6a1G7K4bUVtHogCYr+GuOb\\nbrkvjd5ZpuNbpDhheUQ15U7ih/5LC6cUUISgLDAqBgkqhkiG9w0BCQ4xHTAbMAsG\\nA1UdDwQEAwIDiDAMBgNVHRMBAf8EAjAAMAoGCCqGSM49BAMCA0gAMEUCIAwi8oUK\\nYfUVdflSSs53+57PHrDxV6ot4n6GuChfB61yAiEAqjK1EkIpY5ARU2M5RRB/zJ2K\\n9OaW5J2mVzfEk8Bfi6A=\\n-----END CERTIFICATE REQUEST-----\\n\"}","messageId":"SignCertificate","vendorId":"org.openchargealliance.iso15118pnc"}]
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:15:05,609 de.rwth.idsg.steve.service.CentralSystemService16_Service (qtp247162961-36) - [Data Transfer] Charge point: cp001, Vendor Id: org.openchargealliance.iso15118pnc
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:15:05,609 de.rwth.idsg.steve.service.CentralSystemService16_Service (qtp247162961-36) - [Data Transfer] Message Id: SignCertificate
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:15:05,610 de.rwth.idsg.steve.service.CentralSystemService16_Service (qtp247162961-36) - [Data Transfer] Data: {"certificateType":"V2GCertificate","csr":"-----BEGIN CERTIFICATE REQUEST-----\nMIIBKjCB0QIBADBDMQswCQYDVQQGEwJERTEPMA0GA1UECgwGUGlvbml4MQ4wDAYD\nVQQDDAVjcDAwMTETMBEGCgmSJomT8ixkARkWA0NQTzBZMBMGByqGSM49AgEGCCqG\nSM49AwEHA0IABA1ax+CTmpQuDa46+uPqWvSq0Eh0Jl6a1G7K4bUVtHogCYr+GuOb\nbrkvjd5ZpuNbpDhheUQ15U7ih/5LC6cUUISgLDAqBgkqhkiG9w0BCQ4xHTAbMAsG\nA1UdDwQEAwIDiDAMBgNVHRMBAf8EAjAAMAoGCCqGSM49BAMCA0gAMEUCIAwi8oUK\nYfUVdflSSs53+57PHrDxV6ot4n6GuChfB61yAiEAqjK1EkIpY5ARU2M5RRB/zJ2K\n9OaW5J2mVzfEk8Bfi6A=\n-----END CERTIFICATE REQUEST-----\n"}
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:15:05,611 de.rwth.idsg.steve.ocpp.ws.WebSocketLogger (qtp247162961-36) - [chargeBoxId=cp001, sessionId=3df7f3bc-e076-d275-090f-f2a6eb9d02ac] Sending: [3,"ab6930f6-bf8d-477d-9c1e-d9befb11e239",{"status":"Accepted"}]
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:17:28,991 de.rwth.idsg.steve.ocpp.ws.WebSocketLogger (qtp247162961-27) - [chargeBoxId=cp001, sessionId=3df7f3bc-e076-d275-090f-f2a6eb9d02ac] Received: [2,"1bc50919-858c-49ad-9907-9a788039f6e3","StatusNotification",{"connectorId":1,"errorCode":"NoError","status":"Preparing"}]
        everest-demo-steve-1        | [INFO ] 2023-08-23 05:17:29,008 de.rwth.idsg.steve.ocpp.ws.WebSocketLogger (qtp247162961-27) - [chargeBoxId=cp001, sessionId=3df7f3bc-e076-d275-090f-f2a6eb9d02ac] Sending: [3,"1bc50919-858c-49ad-9907-9a788039f6e3",{}]
    ```

</details>

<details>

<summary> but there are errors at the EVSE level, which seem like they are just a
misconfiguration between the energy management module and the OCPP layer</summary>

```
2023-08-23 05:17:28.938506 [INFO] evse_manager_1:  :: SYS  Session logging started.
2023-08-23 05:17:28.938728 [INFO] evse_manager_1:  :: EVSE IEC Session Started: EVConnected
2023-08-23 05:17:28.989786 [INFO] ocpp:OCPP        :: Logging OCPP messages to html file: /tmp/everest-logs/2023-08-23T05:17:28.938Z-51567328-285c-4ce3-a679-8987a246484f/incomplete-ocpp.html
2023-08-23 05:17:30.301639 [ERRO] energy_manager: std::vector<types::energy::EnforcedLimits> module::EnergyManager::run_optimizer(types::energy::EnergyFlowRequest) :: Trading: Maximum number of trading rounds reached.
2023-08-23 05:17:32.012429 [ERRO] energy_manager: std::vector<types::energy::EnforcedLimits> module::EnergyManager::run_optimizer(types::energy::EnergyFlowRequest) :: Trading: Maximum number of trading rounds reached.
2023-08-23 05:17:33.708568 [ERRO] energy_manager: std::vector<types::energy::EnforcedLimits> module::EnergyManager::run_optimizer(types::energy::EnergyFlowRequest) :: Trading: Maximum number of trading rounds reached.
2023-08-23 05:17:35.264066 [ERRO] energy_manager: std::vector<types::energy::EnforcedLimits> module::EnergyManager::run_optimizer(types::energy::EnergyFlowRequest) :: Trading: Maximum number of trading rounds reached.
2023-08-23 05:17:36.903633 [ERRO] energy_manager: std::vector<types::energy::EnforcedLimits> module::EnergyManager::run_optimizer(types::energy::EnergyFlowRequest) :: Trading: Maximum number of trading rounds reached.
```

</details>

Again, this highlights the power of the software testing approach. We can test
the interoperability of all kinds of configurations in software and make sure
that they work. The plugfests can then focus on hardware issues without having
to get bogged down in software protocol incompatibilities.


## STEP 1: Launch the demo

```
$ curl -o docker-compose.yml https://raw.githubusercontent.com/shankari/everest-demo/main/docker-compose.ocpp.build.yml && docker compose -p everest-ocpp up
```

⚠️  Wait for 5 minutes while steve builds and initializes the database ⚠️

## STEP 2: Create the chargebox

- login to http://127.0.0.1:8180/steve/manager/home (username: admin, password: 1234)
- add a new entry `cp001` by using "Data Management -> Charge Points -> Add New"

## STEP 3: Check the communication

- you should be able to see the communication between the EVSE and the network

```
2023-08-23 05:14:05.390127 [INFO] ocpp:OCPP        :: Reconnecting to plain websocket at uri: ws://steve:8180/steve/websocket/CentralSystemService/cp001 with profile: 0
2023-08-23 05:14:05.446145 [INFO] ocpp:OCPP        :: OCPP client successfully connected to plain websocket server
2023-08-23 05:15:05.595665 [INFO] ocpp:OCPP        :: Checking if OCSP cache should be updated
2023-08-23 05:15:05.596462 [INFO] ocpp:OCPP        :: Requesting OCSP response.
2023-08-23 05:15:05.600287 [INFO] ocpp:OCPP        :: Checking if V2GCertificate has expired
2023-08-23 05:15:05.600821 [INFO] ocpp:OCPP        :: V2GCertificate is invalid in 0 days. Requesting new certificate with certificate signing request
```

## STEP 4: Try to plugin in an EV (will fail)
On your laptop, go to http://127.0.0.1:1880

## TEARDOWN: Clean up after the demo
- Kill the demo process
- Delete files and containers
  - On your laptop: `docker compose -p everest down && rm docker-compose.yml`
  - On PWD: "Close session"

# High level block diagram overview of EVerest capabilities
From https://everest.github.io/nightly/general/01_framework.html
![image](https://everest.github.io/nightly/_images/quick-start-high-level-1.png)
