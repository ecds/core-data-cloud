#!/bin/zsh
# https://github.com/ZeLonewolf/planetiler-scripts/blob/main/local/render_once.sh
# https://download.openstreetmap.fr/extracts/north-america/
# https://download.geofabrik.de/north-america.html
set -e
DIR="${HOME}/data/openstreetmap"
DATE="$(date -u '+%Y-%m-%d %H:%M:%S')"
OF="$DIR/data/georgia42425.pmtiles"
AREA="us_georgia"
cd $DIR
rm -rf ./data/*
mkdir -p "$DIR/data/sources"
mkdir -p "$DIR/data/tmp"
mkdir -p "$DIR/data/layers"
touch $DIR/data/georgia42425.pmtiles
cp $DIR/*.pbf $DIR/data/sources/
echo "******************* updating *********************"
pyosmium-up-to-date -vv --size 5120 "$DIR/data/sources/georgia-latest.osm.pbf"
echo "******************* up to date *********************"
echo "******************* pruning docker *********************"
docker system prune --force
echo "******************* pulling planetiler image *********************"
docker pull ghcr.io/onthegomap/planetiler:latest
echo "******************* running docker 1 *********************"
docker run -e JAVA_TOOL_OPTIONS='-Xmx2g' -v "$DIR/data":/data ghcr.io/onthegomap/planetiler:latest --area="$AREA" --download --download-only --only-fetch-wikidata
echo "******************* running docker 2 *********************"
docker run -e JAVA_TOOL_OPTIONS="-Xmx10g" -v "$(pwd)/data":/data ghcr.io/onthegomap/planetiler:latest --download --area=us_south --output=/data/us_south.pmtiles
docker run -e JAVA_TOOL_OPTIONS="-Xmx24g" -v "${DIR}/data":/data ghcr.io/onthegomap/planetiler:latest --download --area="$AREA" --output=/data/georgia42425.pmtiles --force
#  --bounds=-82.8,30.2,-80.7,32.65 \
echo "******************* uploading to s3 *********************"
aws s3 cp $OF s3://ecds-pmtiles/ --only-show-errors
echo "******************* invalidating distribution *********************"
aws cloudfront create-invalidation --distribution-id E2JG3EJZ7GQA2D --invalidation-batch "{\"Paths\": {\"Quantity\": 1, \"Items\": [\"/*\"]}, \"CallerReference\": \"invalidation-$DATE\"}"
echo "******************* all done *********************"
