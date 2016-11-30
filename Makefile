all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

help:
	@echo "=============================================================================="
	@echo " OpenMapTiles  https://github.com/openmaptiles/openmaptiles "
	@echo "Hints for testing areas                "
	@echo "  make download-geofabrik-list         # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  make list                            # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar "
	@echo "  "
	@echo "Hints for designers:"
	@echo "  ....TODO....                         # start Maputnik "
	@echo "  ....TODO....                         # start Tileserver-gl-light"
	@echo "  make start-mapbox-studio             # start Mapbox Studio"
	@echo "  "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code  "   
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik, and create config file"
	@echo "  make psql                            # start PostgreSQL console "
	@echo "  make psql-list-tables                # list all PostgreSQL tables "
	@echo "  make import-sql-dev                  # start import-sql  /bin/bash terminal "
	@echo "  make import-osm-dev                  # start import-osm  /bin/bash terminal (imposm3)"
	@echo "  make clean-docker                    # remove docker containers, PG data volume "
	@echo "  make forced-clean-sql                # drop all PostgreSQL tables for clean environment "
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tabless"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM informations"
	@echo "  cat ./quickstart.log                 # backup  of the last ./quickstart.sh "
	@echo "  ....TODO....                         # start lukasmartinelli/postgis-editor"
	@echo "  make help                            # help about avaialable commands"  
	@echo "=============================================================================="

build/openmaptiles.tm2source/data.yml:
	mkdir -p build/openmaptiles.tm2source && generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml:
	mkdir -p build && generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql:
	mkdir -p build && generate-sql openmaptiles.yaml > build/tileset.sql

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

list-docker-images:
	docker images | grep openmaptiles

refresh-docker-images:
	docker-compose pull 

remove-docker-images:
	docker rmi -f $(docker images | grep "openmaptiles" | awk "{print \$3}")
	docker rmi osm2vectortiles/mapbox-studio

psql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh

psql-list-tables:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c "\d+"

psql-pg-stat-reset:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'SELECT pg_stat_statements_reset();'

forced-clean-sql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "DROP SCHEMA IF EXISTS public CASCADE ; CREATE SCHEMA IF NOT EXISTS public; "
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION hstore; CREATE EXTENSION postgis; CREATE EXTENSION pg_stat_statements;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "GRANT ALL ON SCHEMA public TO public;COMMENT ON SCHEMA public IS 'standard public schema';"

pgclimb-list-views:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,viewname from pg_views where schemaname='public' order by viewname;" csv

pgclimb-list-tables:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,tablename from pg_tables where schemaname='public' order by tablename;" csv

import-sql-dev:
	docker-compose run --rm import-sql /bin/bash

import-osm-dev:
	docker-compose run --rm import-osm /bin/bash

download-geofabrik:
	@echo ===============  download-geofabrik =======================
	@echo Download area :   $(area)
	@echo [[ example: make download-geofabrik  area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list       ]]
	docker-compose run --rm import-osm  ./download-geofabrik.sh $(area)
	ls -la ./data/$(area).*
	@echo "Generated config file: ./data/docker-compose-config.yml"
	@echo " " 	
	cat ./data/docker-compose-config.yml 
	@echo " " 	

# the `download-geofabrik` error message mention `list`, if the area parameter is wrong. so I created a similar make command
list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

# same as a `make list`
download-geofabrik-list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

start-mapbox-studio:
	docker-compose up mapbox-studio

# work in progress - please don't remove
test_etlgraph:
	generate-etlgraph layers/boundary/boundary.yaml
	generate-etlgraph layers/highway/highway.yaml
	generate-etlgraph layers/housenumber/housenumber.yaml
	generate-etlgraph layers/landuse/landuse.yaml
	generate-etlgraph layers/poi/poi.yaml
	generate-etlgraph layers/water/water.yaml
	generate-etlgraph layers/waterway/waterway.yaml
	generate-etlgraph layers/building/building.yaml
	generate-etlgraph layers/highway_name/highway_name.yaml
	generate-etlgraph layers/landcover/landcover.yaml
	generate-etlgraph layers/place/place.yaml
	generate-etlgraph layers/railway/railway.yaml
	generate-etlgraph layers/water_name/water_name.yaml
