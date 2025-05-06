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
  mysql -u root -p
- Stop replication
  STOP SLAVE; RESET SLAVE ALL;
- Restore the full dump including mysql database
  mysql -u root -p < /path/to/your/backup.sql
- Restart service
  sudo jem service restart

### Step 3: Recreate the Replication User
Since the mysql database was overwritten, the replication user is likely lost.
Log back into MySQL as root:
