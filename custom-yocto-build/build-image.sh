#!/usr/bin/env bash

usage="
	-n        install root certificates for NREL
	-c <dir>  install certificates from a directory
	-m        machine: (arm64vm, amd64vm, rpi4, umwc) default is to
	          build for the Micro Mega Watt Charger
"

MACHINE="umwc"

while getopts ':cnh' option; do
	case "$option" in
		n)  NREL_CERTS=1 ;;
		c)  CUSTOM_CERTS="$OPTARG" ;;
		h)  echo -e "$usage"; exit ;;
		\?) echo -e "illegal option: -$OPTARG\n" >&2
		    echo -e "$usage" >&2
		    exit 1 ;;
	esac
done

docker compose -f docker-compose.kas.yml up -d

if [ -n $NREL_CERTS ]; then
	echo "installing root certs for NREL"
	docker exec --user root custom-yocto-build-kas-1 bash -c \
		"curl -fsSLk -o /usr/local/share/ca-certificates/nrel_root.crt \
		https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_root.pem && \
		curl -fsSLk -o /usr/local/share/ca-certificates/nrel_xca1.crt \
		https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_xca1.pem && \
		update-ca-certificates"
fi

if [ -n $CUSTOM_CERTS ]; then
	echo "installing custom certs"
	docker cp $CUSTOM_CERTS/* custom-yocto-build-kas-1:/usr/local/share/ca-certificates
	docker exec --user root custom-yocto-build-kas-1 update-ca-certificates
fi

docker exec --user root custom-yocto-build-kas-1 mkdir -p /usr/include/python3.11
docker exec --user root custom-yocto-build-kas-1 chown -R builder:builder /workdir

docker compose --project-name custom-yocto-build down

