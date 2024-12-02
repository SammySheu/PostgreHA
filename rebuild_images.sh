cd primary
docker build -t postgres-primary . --no-cache

cd ../replicas
docker build -t postgres-replica . --no-cache

cd ../pgpool
docker build -t postgres-pgpool . --no-cache

