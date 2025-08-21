# Restore Multi-Region Cluster from Database Dump

This guide describes specifics of restoring a database dump in a **multi-region cluster** (MySQL/MariaDB/Percona) on the Virtuozzo Application Platform. It is intended for users who need to restore a MySQL/MariaDB/Percona database from a dump file that includes the `mysql` database, which contains critical information such as user accounts and privileges. Overwriting this database can disrupt replication, so a few extra steps are required to restore the replication user and re-establish replication across the cluster.

This guide assumes you have:

- A multi-region MySQL/MariaDB/Percona cluster set up on the Virtuozzo Application Platform.
- The replication user credentials are defined in the cluster's environment variables: `REPLICA_USER` and `REPLICA_PASS`.
- A backup (dump) from another MySQL/MariaDB/Percona database that includes the `mysql` database. For example, you can use a dump created with the `mysqldump` command:

```bash
mysqldump -u root -p --all-databases > backup.sql
```


## Prepare Primary Node for Restoration

Locate the primary database node of your multi-region cluster in the platform dashboard. This node will be used to restore the database dump.

> **Tip:** Before proceeding, we recommend taking a backup of the current state of your MySQL/MariaDB/Percona cluster. This ensures you can revert changes if needed.

1\. Reset *root* password from the dashboard. Hover over the database primary node, expand the *Additional* menu, and select the *Reset Password* option.

![reset password](/images/manual-multi-region-restoration/01-reset-password.png)

The new password will be sent to the email address associated with your account.

2\. Upload the dump file to the primary node. You can use the [built-in file manager](https://www.virtuozzo.com/application-platform-docs/configuration-file-manager/) or any other method to transfer the file to the node.

![upload dump file](/images/manual-multi-region-restoration/02-upload-dump-file.png)


## Restore Dump on Primary Node

Connect to the primary node via SSH (for example, using the [Web SSH](https://www.virtuozzo.com/application-platform-docs/web-ssh-client/) client) and follow these steps:

1\. Log in to the database server:

```bash
mysql -u root -p
```

![MySQL log in](/images/manual-multi-region-restoration/03-mysql-log-in.png)

2\. Stop the replication process:

```sql
STOP SLAVE; RESET SLAVE ALL;
```

> **Note:** For MySQL 8.0 and newer, use `STOP REPLICA; RESET REPLICA ALL;` instead.

![stop replica](/images/manual-multi-region-restoration/04-stop-replica.png)

3\. Restore the full dump, including the *mysql* database (provide the correct path to your dump file uploaded during the preparation step):

```bash
mysql -u root -p < /path/to/your/backup.sql
```

![restore dump](/images/manual-multi-region-restoration/05-restore-dump.png)

4\. Restart the database service:

```bash
sudo jem service restart
```


## Restore Replication User

Since the *mysql* database was overwritten, the replication and root users are likely lost. So, let's restore them and re-establish replication.

1\. Reset the *root* password from the dashboard, the same way as in the preparation step.

2\. Log back into the database with a new password.

```bash
mysql -u root -p
```

3\. Re-create the replication user with the following SQL commands:

> **Note:** Replace `${REPLICA_USER}` and `${REPLICA_PASS}` with the credentials specified in the appropriate [environment variables](https://www.virtuozzo.com/application-platform-docs/container-variables/).
>
> ![replica credentials](/images/manual-multi-region-restoration/06-replica-credentials.png)

For MySQL:

```sql
CREATE USER IF NOT EXISTS '${REPLICA_USER}'@'%' IDENTIFIED BY '${REPLICA_PASS}';
GRANT USAGE, SELECT, RELOAD, LOCK TABLES, REPLICATION SLAVE, REPLICATION_SLAVE_ADMIN, REPLICATION CLIENT ON *.* TO '${REPLICA_USER}'@'%';
FLUSH PRIVILEGES;
```

For MariaDB:

```sql
CREATE USER IF NOT EXISTS '${REPLICA_USER}'@'%' IDENTIFIED BY '${REPLICA_PASS}';
GRANT USAGE, SELECT, RELOAD, LOCK TABLES, REPLICATION SLAVE, REPLICATION SLAVE ADMIN, SLAVE MONITOR, BINLOG MONITOR ON *.* TO '${REPLICA_USER}'@'%';            
FLUSH PRIVILEGES;
```

For Percona:

```sql
CREATE USER IF NOT EXISTS '${REPLICA_USER}'@'%' IDENTIFIED BY '${REPLICA_PASS}';
GRANT USAGE, SUPER, SELECT, RELOAD, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${REPLICA_USER}'@'%';            
FLUSH PRIVILEGES;
```

![MySQL replica user](/images/manual-multi-region-restoration/07-mysql-replica-user.png)


## Launch Database Recovery Add-On

Stop the database service on all other cluster nodes. It will ensure the recovery process runs from the primary node where the dump was restored and the replication user was recreated.

```bash
sudo jem service stop
```

![stop DB service](/images/manual-multi-region-restoration/08-stop-db-service.png)

Run cluster recovery via the **Multiregion Database Cluster Recovery** add-on, which will:

- Copy the primary node's data to all replica nodes.
- Re-establish replication.
- Start syncing from the current primary.

![recovery add-on](/images/manual-multi-region-restoration/09-recovery-addon.png)

The operation will take some time, depending on the size of the database and the network speed.
