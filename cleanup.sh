sudo rm -rf primary/pgdata replicas/pgdata
sudo mkdir -p primary/pgdata replicas/pgdata
sudo chown -R 999:999 primary/pgdata replicas/pgdata
sudo chmod 700 primary/pgdata replicas/pgdata