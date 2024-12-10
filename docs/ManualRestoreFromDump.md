# Restoring a Galera Cluster from a Database Dump

  When working with a Galera Cluster, it’s important to consider certain limitations. Only InnoDB tables are replicated across nodes. 
Tables using other storage engines, such as *mysql.** tables (which typically use the Aria/MyISAM engines) are not replicated. 
This means changes to these tables are not automatically synchronized and may lead to inconsistencies. 
For more details, refer to the https://mariadb.com/kb/en/mariadb-galera-cluster-known-limitations/ MariaDB Galera Cluster Known Limitations.

Step-by-Step Instructions
1. Load the Database Dump to /tmp/ dorectory on the Master Node
  a. Upload the dump file to the master node using:
  - a File Manager interface.
  - an SFTP.

  b. Restore the dump by running the following command:
  mysql -u<username> -p<password> < /tmp/db_backup.sql
  Replace <username> and <password> with your database credentials.

Alternatively, use tools like phpMyAdmin for an interactive restoration.

2. Stop Services on Non-Master Nodes
SSH into each non-master node using WebSSH or an SSH client.
Run the following command to stop the MariaDB service:
bash
Копировать код
sudo jem service stop
3. Delete the grastate.dat File on Non-Master Nodes
Access each non-master node via SSH or a File Manager.
Remove the Galera state file:
bash
Копировать код
sudo rm /var/lib/mysql/grastate.dat
This ensures the node will initiate a full state transfer (SST) upon service restart.
4. Start Services on Non-Master Nodes
On each non-master node, restart the MariaDB service by running:

bash
Копировать код
sudo jem service start
The non-master nodes will initiate a full SST from the master node, synchronizing all data.

Final Verification
Once the services are up and running, confirm that all nodes have synchronized successfully:
Use the SHOW STATUS LIKE 'wsrep%'; query on each node to check the cluster state.
Ensure all nodes report the same wsrep_cluster_size (indicating the number of nodes).
Key Considerations
Replication of InnoDB Only: Galera Cluster only replicates InnoDB tables. Tables using other storage engines, such as Aria or MyISAM (e.g., mysql.* tables), are not replicated. Ensure you manually synchronize such tables across nodes if required.

Cluster Downtime: During this process, the cluster may experience downtime. Plan accordingly to minimize impact on applications relying on the database.

SST Method: Ensure the SST method configured for your cluster (e.g., xtrabackup or rsync) is functioning correctly to facilitate successful synchronization.

By following these steps, you can restore your Galera cluster from a database dump and ensure all nodes are synchronized while accounting for the non-replication of tables using storage engines other than InnoDB.