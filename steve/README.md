# SteVe Image

The [SteVe](https://github.com/steve-community/steve) image provides a simulated
OCPP Central System for the OCPP 1.6J demo.

## Looking for the SteVe OCPP 1.6J demo?
You've gone to far! Please visit the root directory of this repository to find the OCPP 1.6J Docker Compose file and a one-liner in the README.md for executing it.

## For Demo Developers Only: Build & Configuration Process
There are currently automated and manual steps to building this image.

First, a SteVe image is created without chargers or OCPP ID tags configured and stood up as a service using Docker Compose. This can be done by running the following command from the root of this Git repository:
```shell
    docker compose -f docker-compose.build.yml up -d steve
```

The build process is fairly long, taking anywhere from 5--30 minutes on a modern system. Once an image is built, a SteVe server will be running in a container alongside a MariaDB instance configured to provide a database layer for SteVe.

The remainder of the setup process is manual:
1. With SteVe and MariaDB containers still running, visit http://localhost:8180
2. Log into the SteVe server with username `admin` and password `1234` when prompted.
3. Visit http://localhost:8180/steve/manager/chargepoints/add
4. Enter a `ChargeBox ID` of `cp001` and set `Registration status` to `Accepted`.
5. Click the `Add` button at the bottom of the form.
6. Visit http://localhost:8180/steve/manager/ocppTags/add
7. Enter an `ID Tag` value of `DEADBEEF` and a `Max. Active Transaction Count` of `2`.
8. Click the `Add` button at the bottom of the form.
9. Repeat steps 6--8 for two additional OCPP ID tags with the following attributes:
    - `ID Tag`: `ABC12345`, `Max. Active Transaction Count`: `1`
    - `ID Tag`: `VID:AABBCCDDEEFF`, `Max. Active Transaction Count`: `0`
10. Visit the [EVerest steve-configured package page](https://github.com/EVerest/everest-demo/pkgs/container/everest-demo%2Fsteve-configured) on GitHub and determine the most recent `A.B.C` tag for this image.
11. Use [semantic versioning](https://semver.org) to determine what the appropriate updated tag is for your new version of the `steve-configured` image.
12. From a terminal, commit the running SteVe container using
    ```shell
    docker commit everest-demo-steve-1 ghcr.io/everest/everest-demo/steve-configured:X.Y.Z
    ```
    where `X.Y.Z` should be replaced with the new semantic version for the image you determined in step 11.
13. Repeat steps 10--12 for the running MariaDB container and [EVerest `ocpp-db-compiled` image](https://github.com/EVerest/everest-demo/pkgs/container/everest-demo%2Focpp-db-compiled). Your Docker Commit command should look like the following:
    ```shell
    docker commit everest-demo-ocpp-db-1 ghcr.io/everest/everest-demo/ocpp-db-compiled:X.Y.Z

    ```
    again replacing `X.Y.Z` with the relevant semantic version from step 11.
14. Push each of these newly-created image versions to the EVerest project with
    ```shell
    # Remember to replace the X.Y.Z with your new version tag!
    docker push ghcr.io/everest/everest-demo/steve-configured:X.Y.Z
    ```
    and
    ```shell
    # Remember to replace the X.Y.Z with your new version tag!
    docker push ghcr.io/everest/everest-demo/ocpp-db-compiled:X.Y.Z
    ```

> **Note:** The OCPP ID tags are configured so that `DEADBEEF` (the default) can authenticate against two chargers simultaneously (that is, can be involved in two concurrent transactions). In contrast, `ABC12345` can only work one charger at a time, and `VID:AABBCCDDEEFF` is blocked entirely from charging vehicles. Choosing different combinations of demo connectors and OCPP tags (as well as authenticating before/after plugging in a simulated vehicle) can demonstrate a variety of basic authentication scenarios. The configurations for these IDs can be modified within the SteVe administration webapp to support other scenarios.
>
> The OCPP Tag IDs themselves are defined in the Node-Red flows for the two EVSE demo.
