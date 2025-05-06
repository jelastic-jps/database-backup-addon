# Restore Multi-Region Cluster from Database Dump

This guide assumes you have:
- A multi-region MySQL Cluster.
- A backup (dump) from another environment that includes the mysql database.
- The replication user credentials are defined in the environment variables: REPLICA_USER and REPLICA_PASS.

### Step 1: Prepare the Master Node for Restoration
 - Choose the master node of your MySQL Cluster. Displayed as Primary node
 - Reset root password from Dashbord
 - Upload mysql dump to master node

### Step 2: Restore the Dump on the Master Node
- Log in to MySQL on the master node
  ```
  mysql -u root -p
  ```
- Stop replication
  ```
  STOP SLAVE; RESET SLAVE ALL;
  ```
- Restore the full dump including mysql database
  ```
  mysql -u root -p < /path/to/your/backup.sql
  ```
- Restart service
  ```
  sudo jem service restart
  ```

### Step 3: Recreate the Replication User
Since the mysql database was overwritten, the replication and root users are likely lost.
- Reset root password from Dashbord
- Log back into MySQL as root:
  ```
  mysql -u root -p
  ```
- Create the replication user using the environment variable values:  
  Replace ${REPLICA_USER} and ${REPLICA_PASS} with actual values of environment variables.
  ```
  CREATE USER '${REPLICA_USER}'@'%' IDENTIFIED BY '${REPLICA_PASS}';
  GRANT REPLICATION SLAVE ON *.* TO '${REPLICA_USER}'@'%';
  FLUSH PRIVILEGES;
  ```

### Step 4: Launch the Database Recovery Add-on
Run the Database restore add-on via the cluster dashboard.
This add-on will:
- Copy the master node's data to all replica nodes.
- Re-establish replication.
- Start syncing from the current master.
Depending on the size of the dump, this may take several minutes.
