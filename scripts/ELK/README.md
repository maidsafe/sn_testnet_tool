# ELK for testnets

The scripts in this directory allow us to start metricbeat services along with every node that we start with the `up.sh` script.

## Pre-requisites:
* At the moment, the setup of Elastic and Kibana servers are manual. So for our metricbeat instances to communicate, it is given that we already have instances of Elastic and Kibana servers up and running at the time of running `up.sh` script.


* To setup metricbeat instances automatically, all the nodes pull their `metricbeat.yml` configuration from Maidsafe's Amazon S3 bucket.
Therefore, it is also a given that the `metricbeat.yml` file must also be uploaded with the correct Elastic and Kibana IPs manually before running `up.sh`.
  
Note: All the scripts and files should also be available in `https://safe-testnet-tool.s3.eu-west-2.amazonaws.com/ELK/`    

### To setup an Elastic Server
* Start a DigitalOcean droplet with at least 16GB RAM and 4 vCPUs. This is because ElasticSearch is a resource heavy process and can sometimes crash due to OOM or slowdown due to lack of CPU power.
* SSH into the machine and execute the `install-elasticsearch.sh` script to install the latest ElasticSearch package.
* Replace ElasticSearch's YAML config file at `/etc/elasticsearch/elasticsearch.yml` with the config in `templates/elasticsearch.yml`
* Update the `<ELASTIC-MACHINE-PUBLIC-IP>` in the YAML file to the machine's Public IP.
* Run `systemctl start elasticsearch` to start the process.

To verify if the setup went fine: Open `http://<ELASTIC-MACHINE-PUBLIC-IP>:9200` in a web browser to get an output similar to:

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

### To setup a Kibana Server
* Start a DigitalOcean droplet with at least 8GB RAM and 4 vCPUs. This is because Kibana is a resource heavy process and can sometimes crash due to OOM or slowdown due to lack of CPU power.
* SSH into the machine and execute the `install-kibana.sh` script to install the latest Kibana package.
* Replace Kibana's YAML config file at `/etc/kibana/kibana.yml` with the config in `templates/kibana.yml`
* Update the `<KIBANA-MACHINE-PUBLIC-IP>` in the YAML file to the machine's Public IP.
* Run `systemctl start kibana` to start the process.

To verify if the setup went fine: Open `http://<KIBANA-MACHINE-PUBLIC-IP>:5601` in a web browser to see Kibana's homepage.

## Running

The `install-and-run-metricbeat.sh` script is hooked onto `genesis.tf` and `node.tf` file in the root dir. Therefore, we can directly call `up.sh` to start a testnet with metricbeat instances automatically getting setup and enabled alongside every node that is spun-up.

## License

This SAFE Network library is dual-licensed under the Modified BSD ([LICENSE-BSD](LICENSE-BSD) https://opensource.org/licenses/BSD-3-Clause) or the MIT license ([LICENSE-MIT](LICENSE-MIT) https://opensource.org/licenses/MIT) at your option.

## Contributing

Want to contribute? Great :tada:

There are many ways to give back to the project, whether it be writing new code, fixing bugs, or just reporting errors. All forms of contributions are encouraged!

For instructions on how to contribute, see our [Guide to contributing](https://github.com/maidsafe/QA/blob/master/CONTRIBUTING.md).