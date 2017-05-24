# Postgres-XL High Availability

## Introduction

Postgres-XL High Availability (HA) provides resource agents for GTM, coordinator, and datanode to manage them through Pacemaker. Postgres-XL administrators may use Postgres-XL HA to configure automatic failover in order to minimize downtime.

This documentation explains how to install and configure Postgres-XL and Postgres-XL HA on an example cluster. The cluster has 5 nodes; 1 node (*t1*) for a GTM, 1 node (*t2*) for a coordinator, and 2 nodes (*t3*, *t4*) for datanodes.

## Installation

### Requirements

On each node, software packages for building Postgres-XL and cluster software packages (i.e., Pacemaker, Corosync, and PCS) should be installed.

First, install software packages for building Postgres-XL.

```sh
$ yum install wget gcc readline-devel zlib-devel flex bison
```

Then, install cluster software packages along with various resource agents and fence agents.

```sh
$ yum install pacemaker pcs resource-agents fence-agents-all
```

On each node, execute the following commands to start the `pcsd` service and to enable `pcsd` at system start.

```sh
$ systemctl start pcsd.service
$ systemctl enable pcsd.service
```

And, for convenience, add the following lines to the `/etc/hosts` file in each node to associate IP addresses with hostnames. The IP addresses used below should be replaced with the actual IP addresses depending on the administrator's network environment.

```
192.168.56.11 t1
192.168.56.12 t2
192.168.56.13 t3
192.168.56.14 t4
```

This documentation assumes that the firewall for each node is disabled.

### Building and Installing Postgres-XL

To build and install Postgres-XL, a new user, `postgres`, will be used. Run the following commands as a root on each node to create the user and change the password.

```sh
$ useradd postgres
$ passwd postgres
```

After creating the user, login as `postgres` on node *t1* and run the following commands to build and install Postgres-XL.

> In this documentation, Postgres-XL 9.5r1.5 is used. Other versions are available at [here](http://www.postgres-xl.org/download/).

```sh
$ mkdir -p $HOME/pgxl/src
$ cd $HOME/pgxl/src
$ wget http://files.postgres-xl.org/postgres-xl-9.5r1.5.tar.gz
$ tar -xzf postgres-xl-9.5r1.5.tar.gz
$ cd postgres-xl-9.5r1.5
$ ./configure --prefix=$HOME/pgxl
$ make install-world
```

### Post Setup

If Postgres-XL is installed successfully, append the following lines to the `$HOME/.bashrc` file to add Postgres-XL's binary and library paths to `$PATH` and `$LD_LIBRARY_PATH` environment variables respectively. If an administrator logins as `postgres` next time, those environment variables will be set.

```sh
PATH=$HOME/pgxl/bin:$PATH
export PATH

LD_LIBRARY_PATH=$HOME/pgxl/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
```

### Deploying Postgres-XL

To deploy Postgres-XL to other nodes, use `pgxc_ctl` utility. Before using it, key-based authentication among all the nodes is required to allow `pgxc_ctl` to send commands to other nodes via SSH. The following commands will create an empty configuration file for `pgxc_ctl`.

```sh
[postgres@t1 ~]$ pgxc_ctl
/bin/bash
Installing pgxc_ctl_bash script as /home/postgres/pgxc_ctl/pgxc_ctl_bash.
ERROR: File "/home/postgres/pgxc_ctl/pgxc_ctl.conf" not found or not a regular file. No such file or directory
Installing pgxc_ctl_bash script as /home/postgres/pgxc_ctl/pgxc_ctl_bash.
Reading configuration using /home/postgres/pgxc_ctl/pgxc_ctl_bash --home /home/postgres/pgxc_ctl --configuration /home/postgres/pgxc_ctl/pgxc_ctl.conf
Finished reading configuration.
   ******** PGXC_CTL START ***************

Current directory: /home/postgres/pgxc_ctl
PGXC prepare config empty
PGXC q
```

> The `pgxc_ctl.conf` is not shared among nodes. Therefore, all `pgxc_ctl` commands should be run on node *t1*.

After creating empty `$HOME/pgxc_ctl/pgxc_ctl.conf` file, edit the file and modify `pgxcInstallDir` as follows. Postgres-XL will be deployed to the given directory path.

```
pgxcInstallDir=$HOME/pgxl
```

Finally, run the following commands to deploy Postgres-XL to nodes *t2*, *t3*, and *t4*.

```sh
[postgres@t1 ~]$ pgxc_ctl
/bin/bash
Installing pgxc_ctl_bash script as /home/postgres/pgxc_ctl/pgxc_ctl_bash.
Installing pgxc_ctl_bash script as /home/postgres/pgxc_ctl/pgxc_ctl_bash.
Reading configuration using /home/postgres/pgxc_ctl/pgxc_ctl_bash --home /home/postgres/pgxc_ctl --configuration /home/postgres/pgxc_ctl/pgxc_ctl.conf
Finished reading configuration.
   ******** PGXC_CTL START ***************

Current directory: /home/postgres/pgxc_ctl
PGXC deploy t2 t3 t4
Deploying Postgres-XL components.
Prepare tarball to deploy ...
Deploying to the server t2.
Deploying to the server t3.
Deploying to the server t4.
Deployment done.
```

And do "Post Setup" process in the three nodes.

### Installing Postgres-XL HA Using a RPM Package

Postgres-XL HA can be installed using a RPM package. To install it, run the following commands as a root.

```sh
$ wget https://github.com/bitnine-oss/postgres-xl-ha/archive/postgres-xl-ha-v0.1.0.tar.gz
$ rpm -i postgres-xl-ha-v0.1.0.tar.gz
```

## Creating a Postgres-XL cluster

Before creating the cluster, add `$dataDirRoot` environment variable to `$HOME/.bashrc` on node *t1*. This will be used to specify data directory paths later.

```sh
dataDirRoot=$HOME/DATA/pgxl/nodes
export dataDirRoot
```

### Adding a GTM

Run the following command to add a GTM master to the cluster.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC add gtm master gtm t1 6666 $dataDirRoot/gtm
```

### Adding a Coordinator

Before adding a coordinator, create `$HOME/DATA/pgxl/extra_pg_hba.conf` file with following lines.

```
host all all t1 trust
host all all t2 trust
host all all t3 trust
host all all t4 trust
```

Then, run the following command to add a coordinator to the cluster.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC add coordinator master coord t2 5432 6668 $dataDirRoot/coord none /home/postgres/DATA/pgxl/extra_pg_hba.conf
```

### Adding Datanodes

To add datanodes, run the following commands. These commands will add two datanodes on node *t3* and *t4*.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC add datanode master dn1 t3 5433 6669 $dataDirRoot/dn1 none none /home/postgres/DATA/pgxl/extra_pg_hba.conf
PGXC add datanode master dn2 t4 5434 6670 $dataDirRoot/dn2 none none /home/postgres/DATA/pgxl/extra_pg_hba.conf
```

Those datanodes are master. After adding those datanodes successfully, run the following commands to add slave datanodes of them. Adding slave datanodes takes some time.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC add datanode slave dn1 t4 5433 6669 $dataDirRoot/dn1 none $dataDirRoot/dn1a
PGXC add datanode slave dn2 t3 5434 6670 $dataDirRoot/dn2 none $dataDirRoot/dn2a
```

Finally, an administrator may check the status of the cluster using `monitor all` command.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC monitor all
Running: gtm master
Running: coordinator master coord
Running: datanode master dn1
Running: datanode slave dn1
Running: datanode master dn2
Running: datanode slave dn2
```

## Configuring Postgres-XL HA

To manage the Postgres-XL cluster using Pacemaker, there sould be a Pacemaker cluster for it. This section exmpalins how to configure the Pacemaker cluster and Postgres-XL HA.

### Creating the Pacemaker Cluster

First, set a password to `hacluster` user. The following command needs to be run on all cluster machines as a root.

```sh
$ echo PASSWORD | passwd --stdin hacluster
```

Then, set up the authentication needed for PCS.

> `pcs` commands can be run on any node which is in the cluster. This documentation assumes that all `pcs` commands are run on node *t1*.

> All `pcs` commands should be run as a root user.

```sh
$ pcs cluster auth t1 t2 t3 t4 -u hacluster -p PASSWORD
```

And create a cluster named *postgres-xl* and populate it with *t1*, *t2*, *t3*, and *t4*.

```sh
$ pcs cluster setup --name postgres-xl t1 t2 t3 t4
```

### Starting the Pacemaker Cluster

To start and check the status of the cluster, run the following commands.

```sh
$ pcs cluster start --all
t1: Starting Cluster...
t2: Starting Cluster...
t4: Starting Cluster...
t3: Starting Cluster...
$ pcs status
Cluster name: postgres-xl
Stack: corosync
Current DC: t2 (version 1.1.15-11.el7_3.4-e174ec8) - partition with quorum
Last updated: Mon May 22 22:41:21 2017		Last change: Mon May 22 22:40:26 2017 by hacluster via crmd on t2

4 nodes and 0 resources configured

Online: [ t1 t2 t3 t4 ]

No resources


Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
```

### Setting Cluster Options

With so many devices and possible topologies, it is nearly impossible to include Fencing in a documentation like this. For now it will be disabled. And a resource can be started only if location constraints for the resource are specified.

```sh
$ pcs property set stonith-enabled="false"
$ pcs property set symmetric-cluster="false"

$ pcs resource defaults migration-threshold=1
```

### Creating the GTM Resource

Postgres-XL HA provides a resource agent for GTM, `postgres-xl-gtm`. It supports 5 parameters as follows.

* `user`: The user who starts GTM (default: `postgres`)
* `bindir`: Path to the Postgres-XL binaries (default: `/usr/local/pgsql/bin`)
* `datadir`: Path to the data directory
* `host`: IP address (default: The hostname of the node)
* `port`: Port number (default: 6666)

The following commands enable managing the GTM on node *t1*. The GTM has its database files in the `/home/postgres/DATA/pgxl/nodes/gtm` directory.

```sh
$ pcs cluster cib gtm.xml

$ pcs -f gtm.xml resource create gtm ocf:bitnine:postgres-xl-gtm \
        bindir=/home/postgres/pgxl/bin \
        datadir=/home/postgres/DATA/pgxl/nodes/gtm

$ pcs -f gtm.xml constraint location gtm prefers t1
$ pcs -f gtm.xml constraint location gtm avoids t2 t3 t4

$ pcs cluster cib-push gtm.xml
```

### Creating the Coordinator Resource

Postgres-XL HA provides a resource agent for coordinator, `postgres-xl-coord`. It supports the same 5 parameters `postgres-xl-gtm` does, but the default value for `port` is `5432`.

The following commands enable the coordinator on node *t2*. The coordinator has its database files in the `/home/postgres/DATA/pgxl/nodes/coord` directory.

```sh
$ pcs cluster cib coord.xml

$ pcs -f coord.xml resource create coord ocf:bitnine:postgres-xl-coord \
        bindir=/home/postgres/pgxl/bin \
        datadir=/home/postgres/DATA/pgxl/nodes/coord

$ pcs -f coord.xml constraint location coord prefers t2
$ pcs -f coord.xml constraint location coord avoids t1 t3 t4

$ pcs cluster cib-push coord.xml
```

### Creating the Datanode Resources

HA for datanodes can be set up using the resource agent,`postgres-xl-data`. It supports the same 5 parameters `postgres-xl-coord` does and additional `nodename` parameter to specify the name of the datanode.

> Administrators should create data files in the same directory for master and slave datanodes.

The following commands enable master/slave configuration for datanode *dn1* on node *t3* and *t4* respectively.

```sh
$ pcs cluster cib dn1.xml

$ pcs -f dn1.xml resource create dn1 ocf:bitnine:postgres-xl-data \
        bindir=/home/postgres/pgxl/bin \
        datadir=/home/postgres/DATA/pgxl/nodes/dn1 \
        port=5433 \
        nodename=dn1 \
        op start timeout=60s \
        op stop timeout=60s \
        op promote timeout=30s \
        op demote timeout=120s \
        op monitor interval=15s timeout=10s role="Master" \
        op monitor interval=16s timeout=10s role="Slave"

$ pcs -f dn1.xml resource master dn1-ha dn1 \
        master-max=1 master-node-max=1 \
        clone-max=2 clone-node-max=1

$ pcs -f dn1.xml constraint location dn1-ha prefers t3=1000 t4=0
$ pcs -f dn1.xml constraint location dn1-ha avoids t1 t2

$ pcs cluster cib-push dn1.xml
```

HA for datanode *dn2* also can be enabled in a similar way to datanode *dn1* as follows.

```sh
$ pcs cluster cib dn2.xml

$ pcs -f dn2.xml resource create dn2 ocf:bitnine:postgres-xl-data \
        bindir=/home/postgres/pgxl/bin \
        datadir=/home/postgres/DATA/pgxl/nodes/dn2 \
        port=5434 \
        nodename=dn2 \
        op start timeout=60s \
        op stop timeout=60s \
        op promote timeout=30s \
        op demote timeout=120s \
        op monitor interval=15s timeout=10s role="Master" \
        op monitor interval=16s timeout=10s role="Slave"

$ pcs -f dn2.xml resource master dn2-ha dn2 \
        master-max=1 master-node-max=1 \
        clone-max=2 clone-node-max=1

$ pcs -f dn2.xml constraint location dn2-ha prefers t3=0 t4=1000
$ pcs -f dn2.xml constraint location dn2-ha avoids t1 t2

$ pcs cluster cib-push dn2.xml
```

## Testing Failover

This section demonstrates failure of datanode *dn1* and checks failover on the datanode is properly done.

First, create a test table and insert some tuples.

```sh
[postgres@t1 ~]$ psql -h t2
postgres=# CREATE TABLE disttab(col1 int, col2 int, col3 text) DISTRIBUTE BY HASH(col1);
CREATE TABLE
postgres=# INSERT INTO disttab SELECT generate_series(1,100), generate_series(101, 200), 'foo';
INSERT 0 100
postgres=# SELECT xc_node_id, count(*) FROM disttab GROUP BY xc_node_id;
 xc_node_id | count
------------+-------
 -560021589 |    42
  352366662 |    58
(2 rows)
```

Then, run the following command to stop the datanode.

```sh
[postgres@t1 ~]$ pgxc_ctl
PGXC stop -m immediate datanode master dn1
```

Right after stopping the datanode, run the following query again. The query will fail due to lack of the datanode.

```sh
[postgres@t1 ~]$ psql -h t2
postgres=# SELECT xc_node_id, count(*) FROM disttab GROUP BY xc_node_id;
ERROR:  Failed to get pooled connections
HINT:  This may happen because one or more nodes are currently unreachable, either because of node or network failure.
 Its also possible that the target node may have hit the connection limit or the pooler is configured with low connections.
 Please check if all nodes are running fine and also review max_connections and max_pool_size configuration parameters
```

If the failover on the datanode is propery done, the same query will produce the same result.

> It takes maximum 15 seconds to perform failover because of `op monitor interval=15s timeout=10s role="Master"`.

```sh
[postgres@t1 ~]$ psql -h t2
postgres=# SELECT xc_node_id, count(*) FROM disttab GROUP BY xc_node_id;
 xc_node_id | count
------------+-------
 -560021589 |    42
  352366662 |    58
(2 rows)
```

## Failback

Postgres-XL HA currently does not support automatic failback. Administrators may do it manually.

## Reference

* [Creating a Postgres-XL cluster - Postgres-XL](http://files.postgres-xl.org/documentation/tutorial-createcluster.html)
* [Configuration Explained - Pacemaker](http://clusterlabs.org/doc/en-US/Pacemaker/1.1-pcs/html-single/Pacemaker_Explained/index.html)
* [Quickstart on RHEL 7 - Pacemaker](http://clusterlabs.org/quickstart-redhat.html)
* [High Availability Add-On Administration - RHEL](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/High_Availability_Add-On_Administration/index.html)
* [High Availability Add-On Reference - RHEL](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/High_Availability_Add-On_Reference/index.html)
