# One-minute (excluding download time) EVerest demo

## STEP 1: get access to docker

- If you are a developer, you might already have docker installed on your laptop
    - Check that the terminal has access to `docker` and `docker compose`
- If not, you can get a docker-enabled instance in the cloud using play-with-docker (PWD)
    https://labs.play-with-docker.com/
    - Create a docker account at https://hub.docker.com/signup/ (if you do not already have one)
    - Log in with the account at https://labs.play-with-docker.com/
    - Add a new instance
    - Check that the terminal has access to `docker` and `docker compose`

## STEP 2: Run the demo
- Copy and paste the command for the demo you want to see:
    - simple AC charging station: `curl -o docker-compose.yml https://raw.githubusercontent.com/shankari/everest-demo/main/docker-compose.yml && docker compose -p everest up`

## STEP 3: Interact with the demo
- Open the nodered flows
    - On your laptop, go to http://localhost:1880
    - On PWD, click on the "open port" button and type in 1880

- Open the demo UI
    - Append `/ui` to the URL above

## STEP 4: See the list of modules loaded and the messages transferred between modules
-![Simple AC charging station log screenshot][img/simple_ac_charging_station.png]

## STEP 5: Clean up after the demo
- Kill the demo process
- On your laptop: `docker compose -p everest down && rm docker-compose.yml`
- On PWD: "Close session"

# High level block diagram overview of EVerest capabilities



