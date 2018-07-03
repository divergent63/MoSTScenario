#!/bin/bash

# Monaco SUMO Traffic (MoST) Scenario
#     Copyright (C) 2018
#     Lara CODECA

# exit on error
set -e

if [ -z "$MOST_SCENARIO" ]
then
    echo "Environment variable MOST_SCENARIO is not set."
    echo "Please set MOST_SCENARIO to the root directory."
    echo "Bash example:"
    echo "      in MoSTScenario exec"
    echo '      export MOST_SCENARIO=$(pwd)'
    exit
fi

INPUT="$MOST_SCENARIO/scenario/in"
ROUTES="$INPUT/route"
ADD="$INPUT/add"

OUTPUT="out"
mkdir -p $OUTPUT

echo "Creating the network..."
netconvert -c most.netcfg

echo "Extracting the polygons..."
polyconvert -c most.polycfg

echo "Convert osm & net to Pickle..."
python3 scripts/xml2pickle.py -i most.raw.osm -o $OUTPUT/osm.pkl
python3 scripts/xml2pickle.py -i most.net.xml -o $OUTPUT/net.pkl

echo "Creating Parking Lots..."
python3 scripts/parkings.osm2sumo.py --osm $OUTPUT/osm.pkl --net most.net.xml \
    --cfg duarouter.sumocfg -o $OUTPUT/most.

echo "Creating Public Transports..."
python3 scripts/pt.osm2sumo.py --osm $OUTPUT/osm.pkl --net most.net.xml -o $OUTPUT/most.

echo "Extracting the TAZ from the boundaries..."
python3 scripts/taz.from.net.osm.py --osm $OUTPUT/osm.pkl --net most.net.xml \
    --taz $OUTPUT/most.complete.taz.xml --od $OUTPUT/most.complete.taz.weight.csv \
    --poly $OUTPUT/most.poly.weight

echo "Generate the TAZ for the AoI..."
python3 $SUMO_DEV_TOOLS/edgesInDistricts.py -n most.net.xml -t aoi.taz.shape.xml -o aoi.taz.xml

echo "Extract the parkign areas in the AoI..."
python3 scripts/parkings.in.aoi.py -t aoi.taz.xml -p $OUTPUT/most.parkings.add.xml \
    -o parkings.aoi.json