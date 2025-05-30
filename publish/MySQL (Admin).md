Offer suggestions by opening an [issue](https://github.com/supplefrog/linked-blog-md/issues)

# Table of Contents
- [MySQL Community vs Enterprise](#diction)
- [MySQL Architecture](#mysql-architecture)
    - [Logical](#logical)
    - [Physical](#physical)
    - [InnoDB](#storage-engines)
- [Administration](#administration)
    - [Installation](#installation)
    - [mysqld Management](#mysqld-management)
- [Backup and Restore](#backup-and-restore)
---

### Diction
- MySQL -> relational database management system (RDBMS) - database have schemas
- Schema - table structures (columns, data types) + relationships through primary / foreign keys

| Feature Category              | Community Edition                                                                  | Enterprise Edition                                                                                                                       |
|-------------------------------|------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **License**                   | FOSS (Free and Open Source Software)                                               | Commercial License                                                                                                                                                                                                                                                                                |
| **Kubernetes Support**        | Operator for Kubernetes (InnoDB & NDB clusters, full lifecycle management)         | Same features as Community, with potential enhancements depending on support level                                                                                                                                                                                                               |
| **Backup**                    | Limited (e.g., `mysqldump`)                                                        | Hot backup (server ↑ & running), faster than `mysqldump`, compression with heuristics, zero-storage streaming backup and restore, selective TTS-based backup and restore with table renaming                                                                                                                  |
| **Availability**              | Manual failover and clustering setups                                              | InnoDB Cluster: fault tolerance, data consistency; InnoDB ClusterSet: primary-replica clusters with automatic failover (replacement)    |
| **Scalability**               | Basic concurrency features                                                         | Thread pool for scalable thread management, reduced overhead                                                                           |
| **Stored Programs**           | Standard SQL stored procedures/functions                                           | JavaScript Stored Programs – run inside server, reduce client-server data movement                                                      |
| **Security: Authentication**  | Native MySQL users/passwords                                                       | External authentication modules (Linux PAM, Windows AD), single sign-on, (OS - DBMS) unified credential management, enhanced password policies                                                                                                                                                                |
| **Security: Encryption**      | Basic support (e.g., SSL/TLS)                                                      | Transparent Data Encryption (TDE) for data-at-rest, PCI DSS and GDPR compliance                                                                                                                                                                                                                   |
| **Security: Firewall**        | Not available                                                                      | Enterprise firewall to block unwanted queries                                                                                       |
| **Security: Auditing**        | Not available                                                                      | Advanced auditing tools for compliance and monitoring                                                                              |
| **Monitoring/Management**     | Limited (manual tools or 3rd-party)                                                | Advanced monitoring, built-in enterprise management suite                                                                            |

# MySQL Architecture

## Logical

![Logical Architecture](https://minervadb.xyz/wp-content/uploads/2024/01/MySQL-Thread-Diagram-768x366.jpg)

### Client
- Contains server connectors and APIs
- Sends connection request to server
- CLI - mysql, required by GUI - MySQL Workbench     

### Server

**Authentication**
```mysql
'username'@'hostname' identified by 'password';
```

**Connection Manager**
> Check thread cache;  
> if thread available: provide thread; else create new thread, 1 per client  
> Establish connection

**Security**

Verify if user has privilege for each query

**Parsing**

**Lexer/Lexical Analyzer/Tokenizer/Scanner**

Breaks string into tokens (meaningful elements) - keywords, identifiers, operators, literals

**Parser**
- Checks if tokens follow syntax structure based on rules
- If valid, creates parse tree (Abstract Syntax Tree) - represents logical structure of query
    - Each node represents a SQL operation
    - Edges represent relationships between operations

**Optimizer**
- Reads AST
- Generates multiple candidate execution plans compatible with storage engine:
    - Explores different table access methods - no index/full scan, single/multi-column index, Adapative Hash Index
    - Evaluates possible primary/secondary index usage
    - Considers various join orders (sequence of joining tables)
    - Chooses join methods (e.g., nested loop, hash join)
    - Reorders operations (e.g., applies filters before or after joins) to improve efficiency
    - Considers data distribution and available indexes for join strategies
- Can be influenced by index and join hints:

  `USE INDEX, FORCE INDEX, IGNORE INDEX, STRAIGHT_JOIN`
- Cost-based optimization:
    - References the cost model (I/O, CPU, memory) for every operation in each plan
    - Uses data statistics (row counts, index selectivity, data distribution)
- selects plan with lowest total estimated cost as optimized query plan
- **display query execution plan:**

  `EXPLAIN QUERY;`
  
  `EXPLAIN ANALYZE QUERY;` (8.0+)

**Storage engine performs data lookup in caches & buffers**
- if not found, fetch from disk
- updates to disk

**Query Cache**

Query + result set

- 5.7.20 deprecated
- 8.0 removed (hard to scale)
- Frequently served result sets cached in Redis

**Key Cache stores index blocks**

Used by MyISAM

**Table Open Cache (I/O)**

- Caches file descriptors for open table files
- Used to avoid reopening tables

**Metadata Cache**

Caches structural info e.g., schema, column info

## Physical

### Base Directory - Executables
Default `/bin -> /usr/bin`

| Client Apps            | Use                                                                               |
|:-----------------------|:----------------------------------------------------------------------------------|
| mysql                  | CLI client                                                                        |
| mysqladmin             | CLI for quick server management - status, processlist, kill, flush (reload) tables/logs/privileges, create/drop db, shutdown |
| mysqlbinlog            | Read binary logs                                                                  |
| myisamlog              | Read MyISAM log                                                                   |
| mysqlcheck             | -c check -a analyze -o optimize db [table_name]                                   |
| mysql_config_editor    | Client - store encrypted authentication credentials in .mylogin.cnf for secure passwordless login, useful for scripts |
| mysqldump              | Logical backup                                                                    |
| mysqlimport            | Import CSV/TSV - text format data files directly into tables                      |
| mysql_migrate_keyring  | Migrate encryption keys between keyring components                                |
| mysqlshow              | Quick overview of databases, tables, columns, or indexes                          |
| mysqlslap              | Simulate load from multiple clients and measure performance by the timing of each stage |

| Server Apps                | Use                                                                                         |
|:---------------------------|:--------------------------------------------------------------------------------------------|
| mysqld                     | Server                                                                                      |
| mysqld_pre_systemd         | Initializes datadir (create system tables). Systemd integration -> ExecStartPre -  before server starts |
| mysqldumpslow              | Summarize slow query logs to prioritize queries for tuning                                  |
| mysql_secure_installation  | Set root password, remove anonymous users, disallow remote root login, remove test databases, reload privilege tables |
| mysql_tzinfo_to_sql        | Load system time zones into `mysql` schema                                                  |
| my_print_defaults          | Print options in options groups of option files                                             |

| Additional Utils     | Use                                                                      |
|:---------------------|:-------------------------------------------------------------------------|
| mysqltuner           | Script to analyze and suggest MySQL server optimizations                 |
| mysqlreport          | Generate readable reports from MySQL status and variables                |
| mysqlauditadmin      | Manage MySQL audit plugins and logs                                      |
| mysqlauditgrep       | Search/filter MySQL audit logs                                           |
| mysqldbcompare       | Compare the structure and data of two databases                          |
| mysqldbcopy          | Copy databases or tables between MySQL servers                           |
| mysqldbexport        | Export database objects (schema/data)                                    |
| mysqldbimport        | Import database objects (schema/data)                                    |
| mysqldiff            | Find differences between database schemas                                |
| mysqldiskusage       | Estimate MySQL disk space usage                                          |
| mysqlfailover        | Automatic failover for MySQL replication setups                          |
| mysqlfrm             | Recover or analyze table structure from .frm files                       |
| mysqlindexcheck      | Check for duplicate or redundant indexes                                 |
| mysqlmetagrep        | Search for metadata patterns in database objects                         |
| mysqlprocgrep        | Search/filter running MySQL processes                                    |
| mysqlreplicate       | Set up replication between MySQL servers                                 |
| mysqlrpladmin        | Administer and monitor MySQL replication                                 |
| mysqlrplcheck        | Check replication health and configuration                               |
| mysqlrplshow         | Show replication topology and status                                     |
| mysqlserverclone     | Clone a MySQL server instance                                            |
| mysqlserverinfo      | Display detailed MySQL server information                                |
| mysqluc              | Unified CLI for multiple MySQL utilities                                 |
| mysqluserclone       | Clone MySQL user accounts and privileges                                 |

### MySQL Config File
`/etc/my.cnf`

### Data Directory
`/var/lib/mysql/`

Contains databases and their objects

**Tablespaces and their system schemas**

`mysql.ibd`

contains: 
- **mysql**. (8.0 - removed .frm, .trg, .par files)
  
    user, db, tables_priv, columns_priv, tables, columns, indexes, schemata,
    - mysql.events
    - mysql.routines - stored procedures, reusable SQL statements
    - mysql.triggers - auto-execute procedures in response to events like DML
    - mysql.views - virtual tables rep. query result 

- Data dictionary - internal InnoDB tables for table metadata (Used to create .cfg during table export)

**information_schema** 
- Provides (read only) views (virtual tables) on metadata stored in data dictionary and privilege and grant info in mysql system schema
- refered by `SHOW` command 

`performance_schema/`

.sdi - Serialized Dictionary Information, metadata for objects within performance_schema db

**performance_schema** contains in-memory **tables** of the type performance schema engine for monitoring server execution at runtime

`sys/`

`sysconfig.ibd` - sys_config table - stores sys schema configuration settings

**sys** schema

Views: Summarize and present Performance Schema (and sometimes Information Schema) data in a more user-friendly and actionable format. e.g., views for I/O latency, memory usage, statement summaries, wait events, schema information, etc

Stored Procedures: Automate common diagnostic and performance tasks, such as configuring the Performance Schema or generating reports

Stored Functions: Provide formatting and querying services related to Performance Schema data

`ibdata1`

Default shared tablespace for internal InnoDB structures

**User databases**

`dbname/` 
- (data subdirectory)
- InnoDB File-Per-Table Tablespace (.ibd) - contains table and all its indexes (primary & secondary)
- MyISAM - .myd (data ) & .myi (index)

**Logs**
- General Query Log - all SQL queries received by the server regardless of execution time
- Slow Query Log - queries > specified exec time
- DDL Log - DDL statements
- Binary Log
    - Used for replication and point-in-time recovery
    - Events that describe changes to DB
- Relay Log
    - Replica server data dir/replica-server-name-relay.bin.000001
    - Store events read from source's bin log
    - Processed to replicated changes
- InnoDB Log Files
    - Redo Logs
    - Undo Logs
- Socket File - temp file generated w service start, deleted upon stop
-  File for *PIDs under Socket*

### Storage Engines

**NDBCluster**
- Clustered storage engine for high-availability and scalability

**Memory**
- Store data in RAM for fast access
- For temp, non-persistent data

**CSV**
- Store and retrieve data from csv files

**Blackhole**
- Discards all data written to it
- For testing or logging purposes

**Archive**
- Store and retrieve data from compressed files

**MyISAM**
- Smaller and faster than InnoDB
- More suitable for read-heavy applications

| **ACID Property** | **InnoDB (Default in 5.5)**                                                                                                       | **MyISAM**                          |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| **Atomicity**     | Each transaction is treated as a single unit, either fully completing (commit) or rollback using **undo tablespaces/logs** if any part of the transaction fails   | X |
| **Consistency**   | Supports **foreign keys**, **referential integrity**, and other constraints to maintain data consistency                | X |
| **Isolation**     | Supports **row-level locking**, **transaction isolation levels**, and prevents interference between transactions        | **Table-level locking** leads to lack of isolation |
| **Durability**    | Uses **redo log** (**write-ahead logging**), **doublewrite buffer**, and **crash recovery** for durability              | No recovery in case of crashes             |

![InnoDB Architecture](https://dev.mysql.com/doc/refman/8.4/en/images/innodb-architecture-8-0.png)

**In-Memory Data** - located completely in RAM
- **Buffer Pool**
    - Default 128M, up to 80% server
    - Stores modified pages that haven't been written to disk (dirty pages) - table and index data
    - Least Recently Used (LRU) algorithm
        - New (Young) Sublist (5/8)
            - Head
                - Most accessed pages
            - Tail
        - Old Sublist (3/8)
            - Head
                - New pages
                - Less accessed pages
            - Tail
            - Flushed to data files
    - **Change Buffer (25%, up to 50%)**
        - Caches changes to secondary index pages not currently in buffer pool
        - Merged later when index pages are loaded by buffer pool
    - **Adaptive Hash Index**
        - Constructed dynamically by InnoDB
        - Stores frequently used indexes
        - Speeds up data retrieval from buffer pool
            - B-Tree index lookups -> faster hash-based search
- **Log Buffer**
    - Maintains record of dirty pages in buffer pool
    - Transaction commit/log buffer reaches threshold/regular interval
        - Flush to redo log files

**On-Disk Data**
- **Redo Logs**
    - Write-ahead logging
        - Persistent log of changes, before applied to on-disk pages
    - Changes can be reapplied to data pages if system crashes before/during writing
    - Durability - committed transactions are not lost
    - Temporary redo logs (#ib_redoXXX_tmp) - internal, pre-created spare files to handle log resizing and rotation
- **Tablespaces**
    - **InnoDB** (System) **Tablespace** (`ibdata1`)
        - Change buffer
            - Persists secondary index buffered changes across restarts (durability)
        - Doublewrite Buffer
            - Protects against partial page writes due to crash while writing pages to tables
        - Undo logs
            - In case instance isn't started with undo tablespace
        - Data Dictionary (**8.0 -> mysql.ibd**)
        - Table and Index Data (**5.7 -> For tables without innodb_file_per_table option**)
    - **General Tablespace .ibd**
        - Can host multiple tables
    - **File-Per-Table Tablespace .ibd**
        - Each table has its own .ibd file
    - **Temporary Tablespace**
        - Session (#innodb_temp dir)
            - User-created
                ```mysql
                CREATE TEMPORARY TABLE table_name ();
                ```
            - Internal temp tables - auto created by optimizer for operations like sorting, grouping
                - Optimizer may materialize Common Table Expressions' (CTE - modular query, introduced in 8.0) result sets into temp table if they are frequently referenced in a query
        - Global (ibtmp1)
            - Stores rollback segments for changes to  user-created temp tables
            - Redo logs not needed since not persistent
            - Auto-extending
            - Removed on normal shutdown, recreated on server startup
    - **Undo Tablespaces**
        - Store undo logs
            - Records original data before changes
            - Enable rollback in case transaction not reflected on receiver's end

#### Glossary
**Data**
- Page
    - Unit of data storage - block
    - Default - 16kb
- Table Data
    - Rows
- **Index**
    - Used to locate rows
    - **Primary**
        - Automatically generated with primary keys
        - Each entry in primary index corresponds to unique value in primary key column
        - Clustering - Data stored in same order as index
    - **Secondary**
        - Created on non-primary key/unique column
        - Explicitly created by user to optimize query performance
        - Non-clustering - Do not influence data storage order

# Administration

## [Installation](https://dev.mysql.com/downloads/repo/yum/)

**Packages**
- Import gpg keys to `/etc/pki/rpm-gpg`
```
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
```
- Check package integrity

  `rpm -K pkg.rpm`
- Dependency resolution including glibc version
- Auto install in dirs
- Additional files for compatibility e.g. Systemd service file - configured to initialize server on first boot

- Components divided amongst packages as per function:

`mysql-community-server (`[server apps](#base-directory---executables)`, my.cnf, datadir w ownership, mysqld.service)`

`└── mysql-community-client (`[client apps](#base-directory---executables)`)`
```
    └── mysql-community-libs (shared libraries for MySQL client applications)
        ├── mysql-community-client-plugins`
        └── mysql-community-common (common files for client and server binaries)
```
- Optional:
    - icu-data-files - Unicode support 
    - test - test apps for server
    - debuginfo - debugging symbols - function/variable names, filepaths that is usually stripped from compiled binaries (to secure internal working) for debugging crashes with detailed stack traces
    - devel - development header files and libraries
    - libs-compat - older versions of client libraries for legacy applications that require specific version or binary interface

### [Generic Linux - Tarball](https://downloads.mysql.com/archives/community/)
- All components, and prebuilt binaries for specific glibc dependency
    - support-files
        - SysVinit service files for backward compatibility

## my.cnf
```ini
[mysqld1]

enforce_gtid_consistency = 1
gtid_mode = 1

# expire_logs_days = 7    # binlog expiry
# binlog_expire_logs_seconds = 604800
# binlog_encryption = ON
# log_bin = /var/lib/mysql/mysql-bin.index    # creates bin logs and index file with specified name instead of binlog
general_log = 1
# general_log_file =
slow_query_log = 1
# slow_query_log_file =
# long_query_time = 2

# innodb_buffer_pool_size = 128M    # default, can be increased up to 80% server RAM
# default_authentication_plugin = sha256_password    # 8.0 -> authentication_policy
# default_storage_engine = InnoDB

server-id = 1
# port = 3307
# datadir = /var/lib/mysql1
# log-error = /var/log/mysqld1.log
# lc-messages-dir = /usr/local/mysql/share/
# socket = /var/run/mysql/mysql1.sock
# pid-file = /var/run/mysql/mysqld1.pid
user = mysql

[mysql]
# socket = /var/run/mysql/mysql1.sock # for single instance; client connects to multi instances through socket
# user = root    # unencrypted, not recommended
# password = P@55w0rd
```

### Multiple Instances
| Parameter             | Multiple Instances                                   | Multiple Databases                                |
|-----------------------|------------------------------------------------------|---------------------------------------------------|
| **Data Integrity**    | Data is physically separate; relationships between data in different instances cannot be enforced | logical controls like access controls, data classification, rest & transit encryption, regular monitoring & audits to comply with data protection laws |
| **High Availability** | Stock markets use instance-based failover (clusters) to prevent downtime during peak hours | X |
| **Security**          | Diff memory, configs, users. Banks create separate instances for savings, credit cards, loans and each region for isolating technical problems or security breaches, meeting strict risk and regulatory requirements. <br> Government databases separate classified data by instance for strict access control | Smaller orgs like educational institutes may centralize restricted data for easier management of their platforms due to less risk and compliance needs |
| **Backup, Maintenance & Recovery**  | Enterprises like SaaS providers (prioritize tenant isolation and + high availability) have to backup, monitor, perform routine mainenance, update (patch) and recover for each instance separately, or automate with a script. Avoids downtime for unaffected customers | Easier to manage. Many large social media platforms update the entire database at once—potentially disrupting all users for a short time |
| **Cost Efficiency**   | A multinational retailer invests in separate instances for high-traffic countries | Small startups opt for multiple databases within one instance to cut costs |
| **Performance**       | Each instance has its own dedicated resources (CPU, memory, storage). In a financial institution, a spike in mortgage processing won’t slow down credit card transactions, as each runs on its own instance | X |
| **Scalability**       | A SaaS provider gives large customers their own dedicated instances, allowing them to scale up or move independently, even to different servers or data centers without affecting others | Easy to add more databases, but all share the same instance limits |

---

### Start background process 
**Exits if TTY (parent) closes**

`processname &`

### Daemonize process 
**Changes parent to init (PID=1) if parent dies**

**Partially detach process from TTY:**
- nohup (No Hang Up)
- Sets process to ignore SIGHUP (hangup signal) TTY sends to its children when it closes
- Closes stidn, redirects stdout and stderr to nohup.out

`nohup mysqld --defaults-group-suffix=1 &`

**Completely make process independent from TTY:**
- setsid (set session id)
- creates a new session and process group and makes process its leader, fully independent from TTY, no accidental read or write to closed terminal

`setsid mysqld --defaults-group-suffix=1 &` **or** `setsid bash -c 'mysqld --defaults-group-suffix=1' & # bash run command`

## Systemd Service(s)
**Used to start daemon(s) on boot**

`/etc/systemd/system/service/mysqld@.service` - preferred over `/usr/lib/` to prevent overwriting during updates
```ini
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network-online.target
Wants=network-online.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
# Type=exec # default - service considered started if binary running, or simple/forking - immediately after daemon forks/waiting for parent to exit; for classic daemons - fork and detach. Requires mysqld --daemonize

User=mysql
Group=mysql

# StartLimitIntervalSec=500
# StartLimitBurst=5

Type=notify

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables
ExecStartPre=/usr/bin/mysqld_pre_systemd %I

# Start main service
# ExecStart=/usr/bin/mysqld_mutli start 1,2 $MYSQLD_OPTS
ExecStart=/usr/sbin/mysqld --defaults-group-suffix=@%I $MYSQLD_OPTS

# Use to reference $MYSQLD_OPTS including to switch malloc implementation
# EnvironmentFile=/etc/sysconfig/mysql
EnvironmentFile="MYSQLD_OPTS=--defaults-file=/etc/my.cnf"

# Sets open_files_limit
LimitNOFILE=10000

Restart=on-failure

RestartPreventExitStatus=1

# Set enviroment variable MYSQLD_PARENT_PID. This is required for restart.
Environment=MYSQLD_PARENT_PID=1

PrivateTmp=false
```

## Troubleshoot
- systemctl status
- journalctl -xe
- Reset start limit

`sudo systemctl reset-failed mysqld`
- --help --verbose
    - lists referenced variables

## Security Management
### firewalld
- Identifies incoming traffic from data frame **Network/IP** Layer & **Transport/TCP** Layer **headers** 
- Use rich rules to block service names based on source ips, destination ports
```sh
firewall-cmd --list-all    # services, ports
firewall-cmd --permanent --add-service=mysql
firewall-cmd --permanent --add-service=portid/protocol
firewall-cmd --reload
```

### selinux
`semanage [-h]`

- show ports enabled for specific service

`semanage port -l | grep mysql`

- add/delete port for specific service

`semanage port [-a][-d] -t mysqld_port_t -p tcp 3307`

- set file context for custom datadir
```sh
semanage fcontext -a -t mysqld_db_t "/datadir(/.*)?"
restorecon -Rv /datadir
```

## mysqld Management

### Status

Connection/thread id, (server) uptime, connection (socket), threads, open tables, slow queries, query per sec avg

`status` or `\s`

`mysqladmin [ -u root -p | login-path=local ] status`

**List currently running threads/processes**

Each row = active client connection - connection id, username, hostname, db in use, time (duration of state), state (sorting result, waiting for table metadata lock)

`show processlist -i 2;` # interval = 2s

`mysqladmin [ -u root -p | login-path=local ] processlist -i 2`

`mysqladmin kill pid`

`SELECT * FROM sys.processlist;`

**Identify high load users/problematic queries**

`SELECT * FROM sys.user_summary;`

**Change prompt**

`PROMPT (\u@\h) [\d]\`

**Query Table Data without using DB**

```mysql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'db_name' AND table_type = '';
```

**Log client statements and output**

`tee filename` # appends

Stop

`notee`

### Performance Monitoring / Tuning

**high I/O latency files**

`sys.user_summary_by_file_io`

**full table scan tables**

`sys.schema_tables_with_full_table_scans`

**Database Maintenance**

Monitor buffer pool usage:

`sys.innodb_buffer_stats_by_table`

### System Variables

**Show variables**

`show [global/session/ ] variables [like '%var%'];`

**Set for session**

`set [global/local] variable_name='value';`

**Set persist** - stored in `data_dir/mysqld-auto.cnf`

`set persist variable_name = value;`

### User Management

**Authentication**

`mysql_config_editor print --all` 

Set:

`mysql_config_editor set --login-path=client --host=localhost --user=root --password`

Remove:

`mysql_config_editor remove --login-path=client`

Login:

`mysql --login-path=client`

**Privileges**

`show grants [for current_user/'username'@'hostname']` 

**or**

`select user, host, select_priv, insert_priv, update_priv, delete_priv from mysql.user;`

`select * from information_schema.table_privileges;`

`GRANT select (column1, column2), insert, update, delete, create, drop ON db_name.table_name to 'user'[@'hostname'];`

`GRANT ALL ON db_name.* to 'user'[@'hostname'] WITH GRANT OPTION;`

**Create/drop user**

`create user 'user'[@'hostname'] identified by 'P@55w0rd';`

`drop user 'user1'[@'hostname'], 'user2'[@'hostname'];`

**Reset root password**

`systemctl stop mysqld`

Run mysql as mysql user, not root (my.cnf/param)

`mysqld --skip-grant-tables --skip-networking &`
```mysql
flush privileges;`    # Loads the grant tables
alter user 'root'@'localhost' identified by 'P@55w0rd';

exit
```
`pkill mysql`

### Table Management

[**Create dummy test data**](https://dev.to/siddhantkcode/how-to-inject-simple-dummy-data-at-a-large-scale-in-mysql-eci)

```mysql
CREATE DATABASE IF NOT EXISTS test;

use test;

CREATE TABLE hashes (
  id INT PRIMARY KEY AUTO_INCREMENT, # or UNIQUE
  hash CHAR(64)
);

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO hashes(hash)
WITH RECURSIVE cte (n) AS
(
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM cte WHERE n < 1000000
)
SELECT SHA2(n, 256) FROM cte;
```

**Change auto-increment value**

`ALTER TABLE table_name AUTO_INCREMENT = value;    # if greater than max - next insertion starts w value, else no effect`

**Create general tablespace and add tables**
```mysql
CREATE TABLESPACE ts
    ADD DATAFILE 'ts.ibd'    # base dir is datadir by default
    ENGINE=InnoDB;

CREATE TABLE t1 (
    id INT PRIMARY KEY,
    name VARCHAR(50)
) ENGINE=InnoDB
  TABLESPACE ts;
```

**Switch data dir after install**

```sh
mkdir /newpath
chown -R mysql:mysql /newpath
chmod -R 750 /newpath

systemctl stop mysqld    # copying mid insertion causes parital or mismatched data & index or corruption if copied mid-modification
cp -r /var/lib/mysql /newpath

vi /etc/my.cnf    # datadir=/newpath
systemctl restart mysqld
```

**Change storage engine**

[Backup](#backup-and-restore) before conversion

`ALTER TABLE table_name ENGINE = InnoDB;`

**Stored procedure to convert all MyISAM tables in DB**

```mysql
DROP PROCEDURE IF EXISTS convertToInnodb;
DELIMITER //

CREATE PROCEDURE convertToInnodb()
BEGIN
  mainloop: LOOP
    SELECT TABLE_NAME INTO @convertTable FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
        AND ENGINE = 'MyISAM'
      ORDER BY TABLE_NAME LIMIT 1;
    IF @convertTable IS NULL THEN
      LEAVE mainloop;
    END IF;
    SET @sqltext := CONCAT('ALTER TABLE `', DATABASE(), '`.`', @convertTable, '` ENGINE = InnoDB');
    PREPARE convertTables FROM @sqltext;
    EXECUTE convertTables;
    DEALLOCATE PREPARE convertTables;
    SET @convertTable = NULL;
  END LOOP mainloop;
END//

DELIMITER ;
CALL convertToInnodb();
DROP PROCEDURE IF EXISTS convertToInnodb;
```

## Backup and Restore

| Term     | Meaning                                                    |
|----------|------------------------------------------------------------|
| Cold     | DB offline (locked)                                        |
| Warm     | Table locks (partial access)                               |
| Hot      | No locks (full access)                                     |

| -        | -                                                          |
|----------|------------------------------------------------------------|
| Restore  | Return to original state                                   |
| Recover  | Salvage missing data using specialized tools, partial/full |

### Logical

Produce a set of SQL statements (.sql, csv, other text) to restore the original database object definitions and data

**mysqldump**
```bash
mysqldump [authentication] [-A, --all-databases / -B, --databases db1 db2 / db3 tb1 tb2] [-R] [-E] [--triggers] [ | gzip ] > $(date +"%F_%T").sql[.gz]`

--add-drop-database    # add drop database if exists statement
-R    # routines (stored procedures & functions)
-E    # events (scheduled tasks)
--set-gtid-purged=off    # for DBs w GTIDs, excludes them in backup, creates new tr_ids upon restore
--single-transaction     # no table lock, for both backup and R/W by other user

--no-data    # only schema (database and its objects' structure)
```

**Restore**

`mysql [authentication] db_name < backup.sql`

**mysqlpump**

```bash
mysqlpump [authentication] -B db1 db2 > pump.sql

# number of threads = physical cores should give most perf; if >, context switching will consume CPU time 
--parallel-schemas=4:db1,db2    # number of threads for a new queue for specific DBs

--default-parallelism=4    # number of threads for the default queue that processes all DBs not in separate queues, default 2
```

**Point in Time Recovery** (PITR - Incremental) **using binlog**

| Binary Log Type | Description                                                                                                                  |
|---------------|--------------------------------------------------------------------------------------------------------------------------------|
| Statement     | Logs SQL statements that modify data. Efficient, but can be unreliable for non-deterministic operations like NOW().            |
| Row (Default) | Logs actual row changes. Most reliable for replication, but uses more storage.                                                 |
| Mixed         | Uses statement-based by default, switches to row-based for unsafe (non-deterministic or complex) statements. Efficient + safe. |

`SHOW BINARY LOGS;`

Reset binary logs and gtids, delete logs before a specific date / upto a log file
```mysql
RESET BINARY LOGS AND GTIDS;

PURGE BINARY LOGS BEFORE '2025-05-01 00:00:00';    # or NOW()

PURGE BINARY LOGS TO 'mysql-bin.000123';
```
1. View binary logs with `-v`
    1. `/*! ... */` is a MySQL versioned comment that specifies minimum MySQL version to execute the code inside it, ignored by other DBMS 
2. Convert binary logs to SQL statements and pipe them into the server
```bash
`mysqlbinlog [--start-datetime=, --stop-datetime="2025-05-21 18:00:00" / --start-position=, --stop-position= ] binlog.000001 binlog.000002 | mysql [authentication]`    # only replay changes for specific time/position

--read-from-remote-server    # if binlog encrypted
--include-gtids=server_uuid:tr_id --exclude-gtids=    # used for replication only, gtid_executed gtids aren't replayed

# modified output w flags may not be able to be used to replay changes
-v --verbose [--base64-output=decode-rows]    # Comment reconstructed pseudo-SQL statements out of row events
--base64-output=    # whether to display base64-encoded binlog statements: never, decode-rows disables row-based events, default auto
```

[**mydumper**](https://github.com/mydumper/mydumper/releases)

**MySQL Shell**

### Physical

Actual DB data dir files

**MySQL Enterprise Backup**

[**Percona XtraBackup**](https://www.percona.com/downloads) 

**Tables - Warm Backup**
- **Source**
  ```mysql
  flush tables db.table_name for export;    # locks table for export - copying mid insertion causes parital or mismatched data & index or corruption if copied mid-modification
  cp table_name.ibd table_name.cfg destination/
  unlock tables;
  ```
- **Destination**
  ```mysql
  create table db.table_name(exact table_definition);
  alter table db.table_name discard tablespace;
  alter table db.table_name import tablespace;
  ```

**Logs**

[set login-path=client](#authentication)

`/etc/logrotate.d/mysql`
```ini
/var/log/mysql/mysql_error.log /var/log/mysql/slow_query.log {
compress
create 660 mysql mysql
size 1G
dateext
missingok
notifempty
sharedscripts
postrotate
    /usr/bin/mysql -e 'FLUSH SLOW LOGS; FLUSH ERROR LOGS;'
endscript
rotate 30
}
```

## Upgrade/Downgrade

--upgrade=AUTO (or omitting the option): This is the default behavior. The server automatically determines if upgrades are needed for the data dictionary and system tables based on the detected versions. If an upgrade is required, it will be performed.

--upgrade=MINIMAL: This option tells the server to upgrade the data dictionary, Performance Schema, and INFORMATION_SCHEMA if necessary. It skips the upgrade of other system tables and user schemas. This can be useful for a faster startup when you intend to run mysql_upgrade later to handle the remaining upgrades.

--upgrade=FORCE: This option forces the server to upgrade the data dictionary, Performance Schema, INFORMATION_SCHEMA, and all other system tables and user schemas, even if it doesn't detect a version mismatch. This can be useful in certain troubleshooting scenarios or when you want to ensure all tables are checked and upgraded. Be aware that this can significantly increase startup time as the server will check all objects.

--upgrade=NONE: This is the option you're likely remembering as a way to avoid automatic upgrades. When you use --upgrade=NONE, the server skips all automatic upgrade attempts.

Crucially, if the data dictionary requires an upgrade when you use --upgrade=NONE, the server will refuse to start and exit with an error. This option is not intended for regular use but rather for specific situations where you want to prevent any automatic upgrade and handle it entirely manually (if needed) using mysql_upgrade.
