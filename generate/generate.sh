#!/bin/bash
population=100
state=California
url="http://localhost:3000"
while getopts p:s:u: option
	do
		case "${option}"
		in
			p) population=${OPTARG};;
			s) state=${OPTARG};;
			u) url=${OPTARG};;
		esac
done
git clone https://github.com/synthetichealth/synthea.git
cd synthea || exit 1
sed -e 's/^\(exporter.years_of_history =\).*/\1 0/' -e 's/^\(exporter.csv.export =\).*/\1 true/' src/main/resources/synthea.properties > src/main/resources/synthea.properties.new
mv src/main/resources/synthea.properties.new src/main/resources/synthea.properties
./run_synthea -s 32 -p "$population" "$state"
mv output/csv/allergies.csv ../allergies.csv
mv output/csv/patients.csv ../patients.csv
cd ..
rm -rf synthea
csvtojson allergies.csv > allergies.json
csvtojson patients.csv > patients.json
sed -e '1s/^/{"allergies":/' allergies.json > apidata.json
{
    echo ',"patients":'
    cat patients.json
    echo "}"
} >> apidata.json
rm -rf allergies.csv
rm -rf allergies.json
rm -rf patients.csv
rm -rf patients.json
curl "$url/api/v1/generate" -H "Content-Type: application/json" -X PUT -d "@apidata.json"
