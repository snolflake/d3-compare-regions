#!/usr/bin/env bash

PROVINCES='["USA", "JPN", "GBR", "CHN"]'
MIN_AREA=10000000000

command -v npm >/dev/null 2>&1 || {
    echo >&2 "Please install Node.js v6.x!";
    exit 1;
}

command -v mapshaper >/dev/null 2>&1 || {
    echo >&2 "Installing mapshaper!";
    npm i -g mapshaper;
}

mapshaper \
    -i ./country-info.json ./ne_10m_admin_1_states_provinces/ne_10m_admin_1_states_provinces.shp snap combine-files \
    -rename-layers data,raw \
    -rename-fields target=raw country_code=adm0_a3,country=admin,state=name,state_code=postal \
    \
    -simplify weighted 3% \
    -each target=raw 'country="French Guiana"; country_code="GUF"' where='country_code==="FRA" && state_code==="CY"' \
    -filter target=raw 'country_code!=="ATA"' \
    -filter target=raw 'type_en!=="Overseas department"' \
    -filter-fields target=raw country,country_code,state,state_code \
    -filter target=raw "$PROVINCES.indexOf(this.properties.country_code) !== -1" no-replace name=states \
    \
    -dissolve country_code target=raw no-replace copy-fields=country name=countries \
    -filter-slivers target=countries min-area=1 remove-empty \
    -filter target=countries "this.area > $MIN_AREA" \
    \
    -join data target=countries keys=country_code,alpha-3 fields=region,region-code,sub-region,sub-region-code \
    -rename-fields target=countries region_id=region-code,sub_region=sub-region,sub_region_id=sub-region-code \
    \
    -dissolve sub_region_id target=countries copy-fields=region,region_id,sub_region,sub_region_id no-replace name=sub_regions \
    -dissolve region_id target=sub_regions copy-fields=region_id no-replace name=regions \
    \
    -o ./map.json format=topojson target=regions,sub_regions,countries,states bbox prettify force
