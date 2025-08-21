#!/usr/bin/env bash

usage="
	-n        install root certificates for NREL
	-c <dir>  install certificates from a directory
	-m        machine: (arm64vm, amd64vm, rpi4, umwc) default is to
	          build for the Micro Mega Watt Charger
"

MACHINE="arm64vm"

while getopts ':cnh' option; do
	case "$option" in
		n)  NREL_CERTS=1 ;;
		c)  CUSTOM_CERTS="$OPTARG" ;;
		m)  MACHINE="$OPTARG" ;;
		h)  echo -e "$usage"; exit ;;
		\?) echo -e "illegal option: -$OPTARG\n" >&2
		    echo -e "$usage" >&2
		    exit 1 ;;
	esac
done

docker compose -f docker-compose.kas.yml up -d

if [ -n "$NREL_CERTS" ]; then
	echo "installing root certs for NREL"
	docker exec --user root everest-kas bash -c \
		"curl -fsSLk -o /usr/local/share/ca-certificates/nrel_root.crt \
		https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_root.pem && \
		curl -fsSLk -o /usr/local/share/ca-certificates/nrel_xca1.crt \
		https://raw.github.nrel.gov/TADA/nrel-certs/v20180329/certs/nrel_xca1.pem && \
		update-ca-certificates"
fi

if [ -n "$CUSTOM_CERTS" ]; then
	echo "installing custom certs"
	docker cp $CUSTOM_CERTS/* everest-kas:/usr/local/share/ca-certificates
	docker exec --user root everest-kas update-ca-certificates
fi

docker exec --user root everest-kas mkdir -p /usr/include/python3.11
docker exec --user root everest-kas chown -R builder:builder /workdir

docker cp meta-everest-dev everest-kas:/builder

docker exec --user builder --workdir /workdir everest-kas kas build /builder/meta-everest-dev/${MACHINE}.yml

docker compose -f docker-compose.kas.yml down

