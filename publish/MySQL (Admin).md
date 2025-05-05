# RDBMS
- Tables have relations

## Community Edition
- **FOSS**
- **Operator for Kubernetes**
    - Manages InnoDB & NDB cluster setups inside a Kubernetes cluster
    - Full lifecycle - set up, automating upgrades, backup

## Enterprise Edition

### Backup
- **Hot backup**
    - Online, without interrupting transactions
- **Magnitudes faster (backup and restore) than mysqldump**
- **Compression**
    - Uses heuristics to reduce backups
    - Assesses usage patterns

### Streaming "zero storage" single step backup and restore
- From one server to another without staged storage

### Selective backup & restore (to separate location)
- InnoDB tables using transportable tablespaces (TTS)
- Table renaming on restore of TTS

### Availability

#### InnoDB Cluster
- Data replication across clusters
    - fault tolerance, automated failover, elasticity
    - Built-in group membership management, data consistency guarantees, node failure detection and database failover without manual intervention

#### InnoDB ClusterSet
- Automatic replication from primary to replica clusters
- Failure - primary cluster can be replaced with replica cluster

### Scalability
- **Thread pool**
    - Highly scalable thread handling model
    - reduces overhead in managing client connections and statement execution threads

### JS Stored Programs
- Apps within the MySQL server to minimize client-server data movement

### Security

#### Authentication
- Supports additional plugins (modular components)/modules to integrate external authentication services e.g. Linux PAM, Windows Active Directory
- Allows single sign on - same usernames, passwords, perms
- Eliminates individual system credential management
- More secure - existing password policy

#### Transparent Data Encryption (TDE)
- Enables data-at-rest encryption. Meets regulatory requirements - Payment Card Industry Data Security Standard (PCI DSS), GDPR
- Encrypted before write, decrypted when read

#### Firewall

#### Auditing
- Advanced monitoring and management tools

# System Variables
- show (/global/session) variables(;) like '';
- set persist variable_name = value;

# Architecture

## Logical

### Client
Contains server connectors and APIs
- CLI - mysql
- GUI - MySQL Workbench     

### Server
- **Thread (connection) handler**
    - Checks for available threads in thread pool or assigns a new one
    - Each client gets a thread
- **Authentication**
    - `username@hostname` identified by `password;`
- **Security**
    - Verifies if user has privilege for each query
- **Optimization and Execution**
    - **Lexer**
        - Lexical Analysis/Tokenization
            - Breaks string into tokens - meaningful element
                - Keywords
                - Identifiers
                - Operators
                - Literals
    - **Parser**
        - Analyzes if tokens follow syntax structure based on rules
        - If valid, creates parse tree (Abstract Syntax Tree) - represents query logical structure
            - Each node represents a SQL operation
            - Edges represent relationships between operations
    - **Query Optimizer**
        - Logical query plan derived from parse tree -> optimized query plan, for resp storage engine
        - Cost/rules based optimization
            - Reorders operations like joins, filtering before/after joining
            - Chooses join method e.g. hash, nested loop
            - Chooses primary/secondary index
            - how to perform join by considering data distribution, available indices
    - **Execution Engine**
        - Executes optimized query execution plan
    - **Query Cache**
        Query + result set
        - 5.7.20 deprecated
        - 8.0 removed (hard to scale)
        - Frequently served result sets cached in Redis
    - **Key Cache stores index blocks**
        - Used by MyISAM
    - **Table Open Cache**
        - Stores file descriptors for open tables
            - Needed for accessing tables
        - Reduces overhead of opening and closing tables
    - **Metadata Cache**
        - Stores metadata about database objects

## Physical

### Base Directory
- `/bin -> /usr/bin`
    - Executables
        - mysql - CLI
        - mysqladmin 
            - CLI to interact with mysql server
        - mysqlbinlog
        - myisamlog
        - mysqlcheck
        - mysql_config_editor
        - mysqldump

### MySQL Config File
- `/etc/my.cnf`
    - Buffer Pool Size - MB
        - Default 80% of RAM for server
    - Default Authentication Plugin
    - Locations for
        - Datadir
        - Socket File
        - Error/Server Log
            - /var/log/mysqld.log
            - Can be redirected to System (wide) Log
        - PID File
            - /var/run/mysqld

### Data Directory
- `/var/lib/mysql`
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
        - Binary Log
            - Events that describe changes to DB
            - Server decides which format to use depending on the query:
                - Statement Based Logging
                    - Logs queries that modify data
                - Row-Based Logging
                    - Logs row level data changes - before and after
                - Mixed Logging
                    - Combines both
            - Used for replication and point-in-time recovery
        - General Query Log
            - Log all SQL queries received by the server regardless of execution time
        - Slow Query Log
            - Log queries > specified exec time
        - DDL Log
            - Log DDL statements
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

#### NDBCluster
- Clustered storage engine for high-availability and scalability

#### Memory
- Store data in RAM for fast access
- For temp, non-persistent data

#### CSV
- Store and retrieve data from csv files

#### Blackhole
- Discards all data written to it
- For testing or logging purposes

#### Archive
- Store and retrieve data from compressed files

#### MyISAM
- Smaller and faster than InnoDB
- More suitable for read-heavy applications

| **ACID Property** | **InnoDB (Default in 5.5)**                                                                                                 | **MyISAM** |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| **Atomicity**     | Each transaction is treated as a single unit, either fully completing (commit) or rollback using **undo tablespaces/logs** if any part of the transaction fails                                                                                           | X |
| **Consistency**   | Supports **foreign keys**, **referential integrity**, and other constraints to maintain data consistency         | X |
| **Isolation**     | Supports **row-level locking**, **transaction isolation levels**, and prevents interference between transactions        | **Table-level locking** leads to lack of isolation |
| **Durability**    | Uses **redo log** (**write-ahead logging**), **doublewrite buffer**, and **crash recovery** for durability          | No recovery in case of crashes |

![InnoDB Architecture](https://dev.mysql.com/doc/refman/8.4/en/images/innodb-architecture-8-0.png)

- **In-Memory Data**
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
    - .cfg contains config information for tablespace import
        - **Source**
            - flush tables table_name for export;
            - cp ibd and cfg files
            - unlock tables;
        - **Destination**
            - alter table table_name discard tablespace;
            - alter table table_name import tablespace;
#### Glossary
- **Data**
    - **Page**
        - Unit of data storage - block
        - Default - 16kb
    - **Table Data**
        - Rows
    - **Index**
        - Used to locate rows
        - Primary
            - Automatically generated with primary keys
            - Each entry in primary index corresponds to unique value in primary key column
            - Clustering - Data stored in same order as index
        - Secondary
            - Created on non-primary key/unique column
            - Explicitly created by user to optimize query performance
            - Non-clustering - Do not influence data storage order

# Installation

## Packages
- Dependency resolution including glibc version
- Auto install in dirs
- Additional files for compatibility e.g. Systemd service file - configured to initialize server on first boot
Components divided amongst packages as per function:
    - libs - shared libs for client apps
    - common - common files for db and client libs e.g. config files
    - client
    - server
    **Optional:**
    - test - test suite for server
    - devel - development header files and libraries

## Generic Linux - Tarball
- All components, and prebuilt binaries for specific glibc dependency
    - support-files
        - SysVinit service files for backward compatibility
**my.cnf**
```    
[mysqld]
user=mysql
datadir=
pid-file=
socket=
    
[mysql]
socket=
```
--help verbose
    lists referenced variables
systemctl status
journalctl -xe
