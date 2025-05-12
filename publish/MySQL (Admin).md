### RDBMS - Tables have relations
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
- CLI - mysql, GUI - MySQL Workbench     

### Server

**Authentication**
```
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

- Storage engine performs data lookup in caches & buffers
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
`/bin -> /usr/bin`

- mysql_secure_installation
- mysql - CLI
- mysqladmin - CLI for quick management - status, shutdown, reload privileges, create/drop db
- mysqlbinlog - read binary logs
- myisamlog
- mysqlcheck - check, repair, optimize, or analyze multiple tables
- mysql_config_editor -  Stores MYSQL client authentication credentials in encrypted .mylogin.cnf for secure and easier login
- mysqldump - cold backup

### MySQL Config File
`/etc/my.cnf`

### Data Directory
`/var/lib/mysql/`

Contains databases and their objects

**System schemas and their tablespaces**

`mysql.ibd` (data dictionary tablespace)
- System tables
    - mysql.user
    - mysql.db
    - mysql.tables_priv
    - mysql.columns_priv
- data dictionary tables (8.0 - removed .frm, .trg, .par files)

  All metadata for DB objects, not queriable, only INFORMATION_SCHEMA or `SHOW` cmd

  Used to create .cfg during table export 
    - mysql.tables
    - mysql.columns
    - mysql.indexes
    - mysql.events
    - mysql.schemata
    - mysql.routines (stored procedures, reusable SQL statements)
    - mysql.triggers (auto-execute procedures in response to events like DML)
    - mysql.views (virtual tables rep. query result)

`performance_schema/`

In-memory tables for server performance/event monitoring

`sys/`

Helper views and routines for interpreting performance_schema data

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
    - Server decides which format to use depending on the query:
        - Statement Based Logging - queries that modify data
        - Row-Based Logging - row level data changes - before and after
        - Mixed Logging - combines both
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

| **ACID Property** | **InnoDB (Default in 5.5)**                                                                                                 | **MyISAM**          |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| **Atomicity**     | Each transaction is treated as a single unit, either fully completing (commit) or rollback using **undo tablespaces/logs** if any part of the transaction fails                                                                                                                 | X |
| **Consistency**   | Supports **foreign keys**, **referential integrity**, and other constraints to maintain data consistency                | X |
| **Isolation**     | Supports **row-level locking**, **transaction isolation levels**, and prevents interference between transactions        | **Table-level locking** leads to lack of isolation |
| **Durability**    | Uses **redo log** (**write-ahead logging**), **doublewrite buffer**, and **crash recovery** for durability              | No recovery in case of crashes  |

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
                ```
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

# Admin

## [Installation](https://dev.mysql.com/downloads/repo/yum/)

**Packages**
- Check package integrity

  `rpm -K pkg.rpm`
- Dependency resolution including glibc version
- Auto install in dirs
- Additional files for compatibility e.g. Systemd service file - configured to initialize server on first boot

- Components divided amongst packages as per function:
```
mysql-community-server
└── mysql-community-client
    └── mysql-community-libs
        ├── mysql-community-client-plugins
        └── mysql-community-common
```
- Optional:
    - icu-data-files - Unicode support 
    - test - test suite for server
    - debuginfo - debugging symbols - function/variable names, filepaths that is usually stripped from compiled binaries (to secure internal working) for debugging crashes with detailed stack traces
    - devel - development header files and libraries
    - libs-compat - older versions of client libraries for legacy applications that require specific version or binary interface

### [Generic Linux - Tarball](https://downloads.mysql.com/archives/community/)
- All components, and prebuilt binaries for specific glibc dependency
    - support-files
        - SysVinit service files for backward compatibility

## my.cnf
```
[mysqld_multi]
mysqld = /usr/bin/mysqld_safe
mysqladmin = /usr/bin/mysqladmin
log = /var/log/mysqld_multi.log

[mysqld1]
port = 3306
# socket = /var/run/mysql/mysqld1.sock
# pid-file = /var/run/mysql/mysqld1.pid
datadir = /var/lib/mysql1
log-error = /var/log/mysqld1.log
language = english
lc-messages-dir = /usr/local/mysql/share/english
user = mysql

default_authentication_plugin = sha256_password  # 8.0 -> authentication_policy
default_storage_engine = InnoDB
innodb_buffer_pool_size = 128M  # default, can be increased up to 80% server RAM

[mysql]
# socket = /var/run/mysql/mysqld1.sock
```

## Multiple Instances
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

### & 
Starts background process which exits if TTY closes

### Change parent to init if parent dies: 
**Partially detach process from TTY:**
- nohup (No Hang Up)
- Sets process to ignore SIGHUP (hangup signal) TTY sends to its children when it closes
- Closes stidn, redirects stdout and stderr to nohup.out

`nohup mysqld --defaults-group-suffix=1 &`

**Completely make process independent from TTY:**
- setsid (set session id)
- creates a new session and process group and makes process its leader, fully independent from TTY, no accidental read or write to closed terminal

`setsid mysqld --defaults-group-suffix=1 &` **OR** `setsid bash -c 'mysqld --defaults-group-suffix=1' & # bash run command`

**`mysqld_mutli start 1,2`** - mysqld wrapper to start multiple instances

## Systemd Service(s)
`/etc/systemd/system/service/mysqld@.service` - preferred over `/usr/lib/` to prevent overwriting during updates
```
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

`sudo systemctl reset-failed mysql.service`
- --help --verbose
    - lists referenced variables

## Security Management
### firewalld
- Identifies incoming traffic from data frame **Network/IP** Layer & **Transport/TCP** Layer **headers** 
- Use rich rules to block service names based on source ips, destination ports
```
firewall-cmd --list-all #services, ports
firewall-cmd --permanent --add-service=mysql
firewall-cmd --permanent --add-service=portid/protocol
firewall-cmd --reload
```

### selinux
```
semanage [-h]
```
- show ports enabled for specific service
```
semanage port -l | grep mysql
```
- add/delete port for specific service
```
semanage port [-a][-d] -t mysqld_port_t -p tcp 3307
```

## System Variables
```
show [global/session/ ] variables [like ' '];
```
```
set persist variable_name = value;
```

## User Management (refer GPT chats)

**Authentication**

`mysql_config_editor print --all` 

Set:

`mysql_config_editor set --login-path=local --host=localhost --user=root --password`

Remove:

`mysql_config_editor remove --login-path=client`

Login:

`mysql --login-path=local`


- Reset password
- Create/drop
- Privileges
- Auto increment

## Table Management (refer GPT chats)
- MyISAM -> InnoDB

## Backup and Restore/Recovery

### Cold Backup
**Logical**

mysqldump 

**Tables**
- **Source**
  ```
  # export metadata as .cfg for importing into destination
  flush tables table_name for export;
  cp table_name.ibd table_name.cfg destination/
  unlock tables;
  ```
- **Destination**
  ```  
  alter table table_name discard tablespace;
  alter table table_name import tablespace;
  ```
  
**Physical**

## Upgrade/Downgrade

--upgrade=AUTO (or omitting the option): This is the default behavior. The server automatically determines if upgrades are needed for the data dictionary and system tables based on the detected versions. If an upgrade is required, it will be performed.

--upgrade=MINIMAL: This option tells the server to upgrade the data dictionary, Performance Schema, and INFORMATION_SCHEMA if necessary. It skips the upgrade of other system tables and user schemas. This can be useful for a faster startup when you intend to run mysql_upgrade later to handle the remaining upgrades.

--upgrade=FORCE: This option forces the server to upgrade the data dictionary, Performance Schema, INFORMATION_SCHEMA, and all other system tables and user schemas, even if it doesn't detect a version mismatch. This can be useful in certain troubleshooting scenarios or when you want to ensure all tables are checked and upgraded. Be aware that this can significantly increase startup time as the server will check all objects.

--upgrade=NONE: This is the option you're likely remembering as a way to avoid automatic upgrades. When you use --upgrade=NONE, the server skips all automatic upgrade attempts.

Crucially, if the data dictionary requires an upgrade when you use --upgrade=NONE, the server will refuse to start and exit with an error. This option is not intended for regular use but rather for specific situations where you want to prevent any automatic upgrade and handle it entirely manually (if needed) using mysql_upgrade.
