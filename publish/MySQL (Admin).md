### RDBMS - Tables have relations
| Feature Category                | Community Edition                                                                 | Enterprise Edition                                                                                                                                                                                                                                                                               |
|-------------------------------|-------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **License**                   | FOSS (Free and Open Source Software)                                               | Commercial License                                                                                                                                                                                                                                                                                |
| **Kubernetes Support**        | Operator for Kubernetes (InnoDB & NDB clusters, full lifecycle management)         | Same features as Community, with potential enhancements depending on support level                                                                                                                                                                                                               |
| **Backup**                    | Limited (e.g., `mysqldump`)                                                        | Hot backup (server ↑ & running), faster than `mysqldump`, compression with heuristics, zero-storage streaming backup and restore, selective TTS-based backup and restore with table renaming                                                                                                                  |
| **Availability**              | Manual failover and clustering setups                                              | InnoDB Cluster: fault tolerance, data consistency; InnoDB ClusterSet: primary-replica clusters with automatic failover (replacement)                                                                                                                                                           |
| **Scalability**               | Basic concurrency features                                                         | Thread pool for scalable thread management, reduced overhead                                                                                                                                                                                                                                     |
| **Stored Programs**           | Standard SQL stored procedures/functions                                           | JavaScript Stored Programs – run inside server, reduce client-server data movement                                                                                                                                                                                                          |
| **Security: Authentication** | Native MySQL users/passwords                                                       | External authentication modules (Linux PAM, Windows AD), single sign-on, (OS - DBMS) unified credential management, enhanced password policies                                                                                                                                                              |
| **Security: Encryption**      | Basic support (e.g., SSL/TLS)                                                     | Transparent Data Encryption (TDE) for data-at-rest, PCI DSS and GDPR compliance                                                                                                                                                                                                                   |
| **Security: Firewall**        | Not available                                                                      | Enterprise firewall to block unwanted queries                                                                                                                                                                                                                                                    |
| **Security: Auditing**        | Not available                                                                      | Advanced auditing tools for compliance and monitoring                                                                                                                                                                                                                                             |
| **Monitoring/Management**     | Limited (manual tools or 3rd-party)                                                | Advanced monitoring, built-in enterprise management suite                                                                                                                                                                                                                                        |

# Architecture
- Try and modify architecture notes to merge InnoDB data dir w Physical
- elaborate data flow in Logical

## Logical

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
> if thread available: provide thread; else create new thread - 1 per client
> Establish connection

**Security**
- Verify if user has privilege for each query

**Lexer**
- Lexical Analysis/Tokenization
    - Breaks string into tokens - meaningful element
        - Keywords
        - Identifiers
        - Operators
        - Literals
**Parser**
- Analyzes if tokens follow syntax structure based on rules
- If valid, creates parse tree (Abstract Syntax Tree) - represents query logical structure
    - Each node represents a SQL operation
    - Edges represent relationships between operations
**Query Optimizer**
- Logical query plan derived from parse tree -> optimized query plan, for resp storage engine
- Cost/rules based optimization
    - Reorders operations like joins, filtering before/after joining
    - Chooses join method e.g. hash, nested loop
    - Chooses primary/secondary index
    - how to perform join by considering data distribution, available indices
**Execution Engine**
- Executes optimized query execution plan
**Query Cache**  
Query + result set

- 5.7.20 deprecated
- 8.0 removed (hard to scale)
- Frequently served result sets cached in Redis
**Key Cache stores index blocks**
- Used by MyISAM
**Table Open Cache (I/O)**
- Caches file descriptors for open table files
- Used to avoid reopening tables
**Metadata Cache**
- Caches structural info e.g., schema, column info

## Physical

### Base Directory - Executables
`/bin -> /usr/bin`

- mysql_secure_installation
- mysql - CLI
- mysqladmin - admin CLI
- mysqlbinlog - read binary logs
- myisamlog
- mysqlcheck - check, repair, optimize, or analyze multiple tables
- mysql_config_editor 
- mysqldump - cold backup

### MySQL Config File
`/etc/my.cnf`

### Data Directory
`/var/lib/mysql`

- System Tablespace - ibdata1
- Object Structures
    - Data Subdirectory - Database
        - File-Per-Table Tablespaces
            - Tables - ibd
            - Indexes - ibd
    - System Schema
        - Views
            - Virtual tables representing query result
        - Stored Procedures
            - Set of SQL statements that can be saved and reused
            - Encapsulate DML logic and accept params
        - Triggers
            - Procedures that auto execute in response to specific events like DML on particular table or view
- Logs
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
- Socket File
- *PIDs under Socket* File

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

| **ACID Property** | **InnoDB (Default in 5.5)**                                                                                                 | **MyISAM** |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| **Atomicity**     | Each transaction is treated as a single unit, either fully completing (commit) or rollback using **undo tablespaces/logs** if any part of the transaction fails                                                                                           | X |
| **Consistency**   | Supports **foreign keys**, **referential integrity**, and other constraints to maintain data consistency         | X |
| **Isolation**     | Supports **row-level locking**, **transaction isolation levels**, and prevents interference between transactions        | **Table-level locking** leads to lack of isolation |
| **Durability**    | Uses **redo log** (**write-ahead logging**), **doublewrite buffer**, and **crash recovery** for durability          | No recovery in case of crashes |

![InnoDB Architecture](https://dev.mysql.com/doc/refman/8.4/en/images/innodb-architecture-8-0.png)

- **In-Memory Data** - located completely in RAM
    - **Buffer Pool**
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
- **On-Disk Data**
    - **Redo Logs**
        - Write-ahead logging
            - Persistent log of changes, before applied to on-disk pages
        - Changes can be reapplied to data pages if system crashes before/during writing
        - Durability - committed transactions are not lost
        - Temporary redo logs
    - **Tablespaces**
        - **System Tablespace - ibdata1**
            - Change buffer
                - Persists secondary index buffered changes across restarts (durability)
            - Doublewrite Buffer
                - Protects against partial page writes due to crash while writing pages to tables
            - Data Dictionary
                - Metadata about database objects (8.0 -> file-per-table tablespaces)
                - Used to create cfg files during tablespace export
            - Table and Index Data
                - For tables without innodb_file_per_table option
            - Undo logs
                - In case instance isn't started with undo tablespace
        - **General Tablespace .ibd**
            - Can host multiple tables
        - **File-Per-Table Tablespace .ibd**
            - Each table has own .ibd file
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
- **Metadata**  
  .cfg contains config information for tablespace import  
    - **Source**
        - flush tables table_name for export;
        - cp ibd and cfg files
        - unlock tables;
    - **Destination**
        - alter table table_name discard tablespace;
        - alter table table_name import tablespace;
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
- Dependency resolution including glibc version
- Auto install in dirs
- Additional files for compatibility e.g. Systemd service file - configured to initialize server on first boot

- Components divided amongst packages as per function:
    - libs - shared libs for client apps
    - common - common files for db and client libs e.g. config files
    - client
    - server

    **Optional:**  
    - test - test suite for server
    - devel - development header files and libraries

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
socket = /var/run/mysql/mysqld1.sock  # temp file deleted upon service stop
pid-file = /var/run/mysql/mysqld1.pid
datadir = /var/lib/mysql1
log-error = /var/log/mysqld1.log
user = mysql
default_authentication_plugin = sha256_password  # 8.0 -> authentication_policy
default_storage_engine = InnoDB
innodb_buffer_pool_size = 128M  # default, can be increased up to 80% server RAM

[mysql]
# socket = /var/run/mysql/mysqld1.sock
```

Multi-instance - mysqld_mutli vs nohup (refer GPT chats)

## Systemd Service

## Troubleshoot
- --help --verbose
    - lists referenced variables
- systemctl status
- journalctl -xe

## Security Management
### firewalld
- Identifies incoming traffic from data frame **Network/IP** Layer & **Transport/TCP** Layer **headers** 
- Use rich rules to block service names based on source ips, destination ports
```
firewalld --list-services
firewalld --list-ports
```

add firewalld rules

### selinux
- show ports enabled for services
```
semanage port -l
``` 

add selinux rules

## System Variables
```
show [global/session/ ] variables [like ' '];
```
```
set persist variable_name = value;
```

## User Management (refer GPT chats)
- Reset password
- Create/drop
- Privileges
- Auto increment

## Table Management (refer GPT chats)
- MyISAM -> InnoDB
- Cold Backup - import table, mysqldump - logical, vs physical backup

## Backup and Restore/Recovery

## Upgrade/Downgrade

--upgrade=AUTO (or omitting the option): This is the default behavior. The server automatically determines if upgrades are needed for the data dictionary and system tables based on the detected versions. If an upgrade is required, it will be performed.

--upgrade=MINIMAL: This option tells the server to upgrade the data dictionary, Performance Schema, and INFORMATION_SCHEMA if necessary. It skips the upgrade of other system tables and user schemas. This can be useful for a faster startup when you intend to run mysql_upgrade later to handle the remaining upgrades.

--upgrade=FORCE: This option forces the server to upgrade the data dictionary, Performance Schema, INFORMATION_SCHEMA, and all other system tables and user schemas, even if it doesn't detect a version mismatch. This can be useful in certain troubleshooting scenarios or when you want to ensure all tables are checked and upgraded. Be aware that this can significantly increase startup time as the server will check all objects.

--upgrade=NONE: This is the option you're likely remembering as a way to avoid automatic upgrades. When you use --upgrade=NONE, the server skips all automatic upgrade attempts.

Crucially, if the data dictionary requires an upgrade when you use --upgrade=NONE, the server will refuse to start and exit with an error. This option is not intended for regular use but rather for specific situations where you want to prevent any automatic upgrade and handle it entirely manually (if needed) using mysql_upgrade.
