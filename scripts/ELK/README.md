# ELK for testnets

The scripts in this directory allow us to start metricbeat services along with every node that we start with the `up.sh` script.

## Pre-requisites:
* At the moment, the setup of Elastic and Kibana servers are manual. So for our metricbeat instances to communicate, it is given that we already have instances of Elastic and Kibana servers up and running at the time of running `up.sh` script.


* To setup metricbeat instances automatically, all the nodes pull their `metricbeat.yml` configuration from Maidsafe's Amazon S3 bucket.
Therefore, it is also a given that the `metricbeat.yml` file must also be uploaded with the correct Elastic and Kibana IPs manually before running `up.sh`.

## Running

The `install-and-run-metricbeat.sh` script is hooked onto `genesis.tf` and `node.tf` file in the root dir. Therefore, we can directly call `up.sh` to start a testnet with metricbeat instances automatically getting setup and enabled alongside every node that is spun-up.

## License

This SAFE Network library is dual-licensed under the Modified BSD ([LICENSE-BSD](LICENSE-BSD) https://opensource.org/licenses/BSD-3-Clause) or the MIT license ([LICENSE-MIT](LICENSE-MIT) https://opensource.org/licenses/MIT) at your option.

## Contributing

Want to contribute? Great :tada:

There are many ways to give back to the project, whether it be writing new code, fixing bugs, or just reporting errors. All forms of contributions are encouraged!

For instructions on how to contribute, see our [Guide to contributing](https://github.com/maidsafe/QA/blob/master/CONTRIBUTING.md).