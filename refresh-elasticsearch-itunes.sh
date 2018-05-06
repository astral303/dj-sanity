ITUNES_LIB_XML=~/Music/DJ\ Music/iTunes\ Library.xml

mkdir -p target

echo Exporting trax from iTunes....
itunes-data --tracks target/trax.json "$ITUNES_LIB_XML"

echo Deleting old index...
curl -XDELETE localhost:9200/djtrax; echo

echo Creating new index...
curl -XPUT localhost:9200/djtrax; echo

INPUT_COUNT=`cat target/trax.json | jq -c '.[]' | wc -l`
echo Importing $INPUT_COUNT tracks

echo Insert new values
cat target/trax.json | jq -c '.[] | {"index": {"_index": "djtrax", "_type": "track", "_id": ."Track ID"}}, .' | curl -XPOST 'localhost:9200/_bulk' -H 'Content-Type: application/json' --data-binary @- | jq -c '.errors,.items[]' > target/import-results.json

echo Import into ES complete. Has errors?
grep -v "status..201" target/import-results.json | tee target/import-errors.json

curl localhost:9200/djtrax/_refresh; echo

echo "Input count: ${INPUT_COUNT}. Count in ES:"
curl localhost:9200/djtrax/_count; echo
