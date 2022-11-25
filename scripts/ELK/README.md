# Elastic Stack for SAFE Network Testnets

## Overview

#### Elastic and Kibana
Elastic Stack is a set of free and open tools for data ingestion, enrichment, storage, analysis, and visualization. Elasticsearch is the central component of the stack and raw 
data flows into Elasticsearch from a variety of sources including process and system logs, system metrics, and custom data from web applications. Data ingestion is the process by 
which this raw data is parsed, normalized, and enriched before it is indexed in Elasticsearch. 

Once indexed in Elasticsearch, users can run complex queries against their data and use aggregations to retrieve complex summaries of their data. Kibana is the aptly glorified 
front-end for Elastic, users can create powerful visualizations of their data, share dashboards, and manage the Elastic Stack all from Kibana. Elastic also it includes a rich 
collection of lightweight data and metrics shipping agents known as Beats for sending data to Elasticsearch.


#### Beats(MetricBeat)

Beats is a free and open platform for single-purpose data shippers. They are services that send specific data from the machines that they run in, to Elasticsearch which is capable 
of storing and indexing hundereds/thousands of such instances. MetricBeat collects metrics from systems and services. From CPU to memory, Redis to NGINX, and much more, Metricbeat 
is a lightweight way to send system and service statistics to ELK stack.

## Setup for monintoring testnets

### Elastic

Elastic is the first service that needs to be setup. This is also where we would need to set up security(API keys, HTTPs/TLS certifications etc) for the stack in case we choose to 
share our dashboards to external users. 

* We first need to spin up a capable machine with atlest a 4-core CPU and 8GB RAM
* Run the following command from [sn_testnet_tool](https://github.com/maidsafe/sn_testnet_tool) repository(local) to copy the script to the Elastic node:
```
scp ./scripts/ELK/install-elasticsearch.sh root@<ELASTIC-MACHINE-PUBLIC-IP>:~/.
```
* Then SSH into the Elastic node and execute the script with `./install-elasticsearch.sh`
* The script will perform the below steps:
    * Pull the basic config for setting up ElasticSearch from the following URL  and place it at host's `/etc/elasticsearch/elasticsearch.yml`: 
https://raw.githubusercontent.com/maidsafe/sn_testnet_tool/main/scripts/ELK/templates/elasticsearch.yml
    * Update the IP placeholder to point to the hosts's public IP.
    * Start the elastic service by running `systemctl start elasticsearch` as root
    
Note(optional): The config can be tweaked to setup security if necesary in the future

This will start an Elasticsearch service at: `<ELASTIC-MACHINE-PUBLIC-IP>:9200`. To verify if ElasticSearch is succesfully up and running, open 
`http://<ELASTIC-MACHINE-PUBLIC-IP>:9200` in a web browser to get an output similar to:

```
{
  "name" : "sn-elastic",
  "cluster_name" : "sn_testnet_mointor",
  "cluster_uuid" : "Wkoc-HBpTdalv2KRYpuf-g",
  "version" : {
    "number" : "8.1.2",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "31df9689e80bad366ac20176aa7f2371ea5eb4c1",
    "build_date" : "2022-03-29T21:18:59.991429448Z",
    "build_snapshot" : false,
    "lucene_version" : "9.0.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### Kibana

Once elasticsearch service is successfully setup and running, we can now start up the front-end service Kibana(just like elasticsearch): 

* Spin up a machine with a minimum of 4-core CPU and 8GB of RAM.
* Run the following command from [sn_testnet_tool](https://github.com/maidsafe/sn_testnet_tool) repository(local) to copy script to the Kibana node.
```
scp ./scripts/ELK/install-kibana.sh root@<KIBANA-MACHINE-PUBLIC-IP>:~/.
```  
* Then SSH into the Kibana node. 
* The copied script takes ElasticSearch machine's IP as an argument to setup Kibana config, therefore run the script in the following format:
```
./install-kibana.sh <ELASTIC-MACHINE-PUBLIC-IP>
```
* On execution, the script will perform the below steps:
    * Pull the basic config for setting up Kibana from the following URL and place it at host's `/etc/kibana/kibana.yml`: 
https://raw.githubusercontent.com/maidsafe/sn_testnet_tool/main/scripts/ELK/templates/kibana.yml
    * Update the IP field to point to the hosts's public.
    * Start the elastic service by running `systemctl start kibana` as root

Note(optional): The config can be tweaked to setup security if necessary in the future

Kibana usually takes a couple of minutes to start it's serivce, therefore please allow some wait time before proceeding.

Likewise with ElasticSearch, this will start a Kibana instance at `<KIBANA-MACHINE-PUBLIC-IP>:5601`. To verify if the setup went fine: open 
`http://<KIBANA-MACHINE-PUBLIC-IP>:5601` in a web browser to see Kibana's homepage.

### Metricbeat

Metricbeat is automatically hooked onto to all our D.O. nodes via terraform using the `install-and-run-metricbeat.sh` script at 
https://github.com/maidsafe/sn_testnet_tool/blob/main/scripts/ELK/install-and-run-metricbeat.sh.

**The only pre-requisite for metricbeat to work is to have a valid metricbeat config at https://sn-node.s3.eu-west-2.amazonaws.com/testnet_tool/metricbeat.yml**. The template for a 
valid config is at https://github.com/maidsafe/sn_testnet_tool/blob/main/scripts/ELK/templates/metricbeat.yml. The config needs to be updated with the public IPs for Elastic and 
Kibana services that we have started above and needs to be placed at the aforementioned S3 storage location(https://sn-node.s3.eu-west-2.amazonaws.com/testnet_tool/metricbeat.yml). 
This will then be picked up by all nodes that get spun-up with the sn_testnet_tool to start their metricbeat services.



## Ready-made visualizations

- There is a readily availabe dashboard provided by metricbeat at `http://<KIBANA-IP>:5601/app/dashboards#/view/Metricbeat-system-overview-ecs` that gives us an overview of all 
the metricbeat nodes that are connected to the ELK stack. 
- Another place to mointor the nodes is at `http://<KIBANA-IP>:5601/app/metrics/inventory` where we can scrutinize all the nodes individually using filters and look into their 
details.


## Futher optimizations

The whole setup process can be automated via using Ansible to provision machines and take note of their IPs to furnish the configs such that metricbeat setup does not have to rely 
on S3 locations to fetch configs.
