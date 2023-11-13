# Using Microbenchmark Suites to Detect Application Performance Changes

This repository contains all scripts, results, and further information related to our paper **Using Microbenchmark Suites to Detect Application Performance Changes**.

Software performance changes are costly and often hard to detect pre-release. 
Similar to software testing frameworks, either application benchmarks or microbenchmarks can be integrated into quality assurance pipelines to detect performance changes before releasing a new application version. Unfortunately, extensive benchmarking studies usually take several hours which is problematic when examining dozens of daily code changes in detail; hence, trade-offs have to be made. Optimized microbenchmark suites, which only include a small subset of the microbenchmarks, could solve this problem, but should still reliably detect (almost) all application performance changes such as an increased request latency. It is, however, unclear whether microbenchmarks and application benchmarks detect the same performance problems and whether one can be a proxy for the other.

In our paper, we explore whether microbenchmark suites can detect the same application performance changes as an application benchmark. For this, we run extensive benchmark experiments with both the complete and the optimized microbenchmark suites of [InfluxDB](https://github.com/influxdata/influxdb/tree/2.0) and [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) and compare their results to the respective results of an application benchmark. We do this for 70 and 110 commits respectively. Our results show that it is indeed possible to detect application performance changes using an optimized microbenchmark suite. This detection, however, (i) is only possible when the optimized microbenchmark suite covers all application-relevant code sections, (ii) is prone to false alarms, and (iii) cannot precisely quantify the impact on application performance. Overall, an optimized microbenchmark suite can, thus, provide fast performance feedback to developers (e.g., as part of a local build process), help to estimate the impact of code changes on application performance, and support a detailed analysis while a daily application benchmark detects major performance problems. Thus, although a regular application benchmark cannot be substituted, our results motivate further studies to validate and optimize microbenchmark suites.


# Research

If you use (parts of) this software in a publication, please cite it as:

## Text

Martin Grambow, Denis Kovalev, Christoph Laaber, Philipp Leitner, David Bermbach. Using Microbenchmark Suites to Detect Application Performance Changes. In: IEEE Transactions on Cloud Computing. IEEE 2022.

## BibTeX

```
@article{grambow_using_2022,
	title = {{Using Microbenchmark Suites to Detect Application Performance Changes}},
	journal = {{IEEE} Transactions on Cloud Computing},
	volume = {Early Access},
	author = {Grambow, Martin and Kovalev, Denis and Laaber, Christoph Laaber and Leitner, Philipp and Bermbach, David},
	year = {2022}
}
```

For a full list of publications, please see [our website](https://www.tu.berlin/en/mcc/research/publications/).

## Replication Package

A full replication package including all raw result files is availabe at Deposit Once: http://dx.doi.org/10.14279/depositonce-15532

Files:
- `results_all.zip`: all raw result files 
- `results_aggr.zip`: aggregated result files (see section analysis)
- `scripts.zip`:
	- `analysis`: Scripts to analyze the result files
	- `appBenchmarks`: Scripts to run the application benchmarks
	- `createCommitTable`: Scripts to create the commit tables
	- `GoABS`: Scripts to run the microbenchmark suites using RMIT execution
	- `gocg`: Scripts to analyse the call graphs and find the optimal MB suites
	- `microbenchmarks`: Scripts to setup and run the microbenchmarks 
	- `optimizingMB-Suite`: Scripts to generate the call graphs 


# License

The code in this repository is licensed under the terms of the [MIT](./LICENSE) license.


# Structure

- `analysis`: Scripts to analyze the result files
- `appBenchmarks`: Scripts to run the application benchmarks
- `createCommitTable`: Scripts to create the commit tables
- `microbenchmarks`: Scripts to setup and run the microbenchmarks 
- `optimizingMB-Suite`: Scripts to generate the call graphs
- `results_aggr`: Aggregated result files (see section analysis)


# Howto run the experiments and reproduce the results (e.g., for InfluxDB):

## General setup
1. Clone this project

``` git clone https://github.com/martingrambow/benchmarkStrategy ```


2. Install google cloud sdk

```
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get install apt-transport-https ca-certificates gnupg

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt-get update && sudo apt-get install google-cloud-sdk

gcloud auth activate-service-account --key-file=microbenchmarkevaluation-275929759504.json
```

3. Install golang and graphviz

```
sudo apt-get install golang

sudo apt-get install graphviz
```

4. Create a google cloud project

- Create Service Account and download json key 

- activate compute engine


5 Open Firewall (e.g., InfluxDB traffic) 

- (e.g., Open ports 8086, 8087, 80, and 81 in the firewall)


## Run application benchmarks

1. Navigate to the application benchmark folder of the respective system, i.e., "appBenchmarks/influxdb" or "appBenchmarks/vm" 
2. Check the commitTable.csv 
3. Start the application benchmark using the main.sh script and three arguments:
	1. Start commit number
	2. End commit cumber
	3. Run number

E.g., the script runs an application benchmark for every commit from 1 to 120 and saves the results in a folder named `run1`.

```
cd appBenchmarks/influxdb

screen -d -m -L -Logfile experiment1.log ./main.sh 1 120 1

```

To run AA-test, replace the commit table name in the main.sh script with a file which refers to the AA-test commit table and run the script.

## Run complete microbenchmark suite

1. Navigate to the microbenchmarks folder of the respective system
2. Check the commitTable.csv 
3. Rename the file abs_config_all.json to abs_config.json
4. Start the application benchmark using the main.sh script and three arguments:
	1. Start commit number
	2. End commit cumber
	3. Run number

E.g., the script runs an application benchmark for every commit from 1 to 120 and saves the results in a folder named `run1`.

```
cd microbenchmarks/influxdb

screen -d -m -L -Logfile experiment1.log ./main.sh 1 120 1

```

## Find optimized microbenchmark suite


1.  Generate application benchmark call graph
	1. Move to the respective folder
	`cd optimizingMB-Suite/cgApp_influxdb`
	2. Adjust the 0_main.sh and enter the base commit
	3. Run `./0_main.sh` and save the generated .pprof and .dot file
2. Generate call graphs for all microbenchmarks 
	1. Move to the respective folder
	`cd optimizingMB-Suite/cgMicro_influxdb`
	2. Adjust the 0_main.sh and enter the base commit
	3. Review the abs_config.json configuration
	4. run `./0_main.sh` and save the generated .pprof and .dot files (copy the result folder)
3. Transform pprof profiles to dot files
	1. Clone the gocg tool: https://bitbucket.org/sealuzh/gocg/src/master/ (this tool is also part of our replication package)
	2. Run `gocg/cmd/transform_profiles` with 3 positional arguments:
		1. Folder with generated .pprof files of microbenchmarks 
		2. Folder to which the .dot files will be written
		3. Configuration parameters: type:maximumNumberOfNodes:minmalNodeFraction:MinimalEdgeFraction
			- will generate dot files
			- all nodes (not only the most important ones) should be included
			- all nodes and edge should be included, even if their fraction is very small
			
	```
	gocg/cmd/transform_profiles \
		../benchmarkStrategy/results_all/optimizing_influx/micro/profiles \
		../benchmarkStrategy/results_all/optimizing_influx/micro/dots
		dot:100000:0.000:0.000
	
	```
4. Determine practical relevance (optional)
	1. Clone the gocg tool: https://bitbucket.org/sealuzh/gocg/src/master/
	2. Run `/gocg/cmd/overlap` with 4 arguments
		1. project name to differ between project and library nodes
		2. folder with application benchmark call graph 
		3. folder with microbenchmark call graphs 
		4. output folder
		
	```
	/gocg/cmd/overlap \
		github.com/influxdata/influxdb \
		../benchmarkStrategy/results_all/optimizing_influx/app \
		../benchmarkStrategy/results_all/optimizing_influx/micro/dots \
		../benchmarkStrategy/results_all/optimizing_influx/overlap
	```
	
	3. View the file struct_node_overlap.csv in the output folder 
		- The file lists the number of every microbenchmark and the respective overlap with the application benchmark call graph 
		- There are two metrics for every microbenchmark: one considering project-only nodes, another considering all nodes
		- There is an aggreated "ALL" row which states the practical relevance
4. Remove redundancies
	1. Run `gocg/cmd/minimization` with 4 arguments 
		1. project name to differ between project and library nodes
		2. folder with application benchmark call graph 
		3. folder with microbenchmark call graphs 
		4. output folder
		
	```
	/gocg/cmd/minimization \
		github.com/influxdata/influxdb \
		../benchmarkStrategy/results_all/optimizing_influx/app \
		../benchmarkStrategy/results_all/optimizing_influx/micro/dots \
		../benchmarkStrategy/results_all/optimizing_influx/overlap
	```
	
	2. Review the 4 additional files in the output folder 	
		- The file app_minFile_GreedySystem.csv shows the optimized suite without redundancies 
		
5. Recommend functions

## Run optimized microbenchmark suite

1. Navigate to the microbenchmarks folder of the respective system
2. Check the commitTable.csv 
3. Rename the file abs_config_opti.json to abs_config.json (and/or adjust the microbenchmark names in the file)
4. Start the application benchmark using the main.sh script and three arguments:
	1. Start commit number
	2. End commit cumber
	3. Run number

E.g., the script runs an application benchmark for every commit from 1 to 120 and saves the results in a folder named `run1`.

```
cd microbenchmarks/influxdb

screen -d -m -L -Logfile experiment1.log ./main.sh 1 120 1

```

# How to analyze the results

1. Open the `analyis` folder as a Pycharm project
2. The analysis folder:
	- `appBenchmarks_influxdb` and `appBenchmarks_vm`:
		- `app_AATests_prepare_XX.ipynb`: Aggregates raw results in a csv file
		- `app_AATests_bootstrap_XX.ipynb`: Runs the bootstrapping on the csv file and finds median value and CIs 
		- `app_regression_aggregate_XX.ipynb`: Aggregates raw results in csv file
		- `app_regression_bootstrap_XX.ipynb`: Finds median performance changes and determines CIs
		- `app_regression_draw_XX.ipynb`: Draws performance history
	- `microbenchmarks_influxdb` and `microbenchmarks_vm`:
		- `micro_regression_bootstrap_prepare_XX.ipynb`: Aggregates raw results
		- `micro_regression_bootstrap_analyze_XX.ipynb`: Finds median performance change and determines CIs
		- `micro_regression_bootstrap_draw_XX.ipynb`: Draws performance history
	- `paperplots`: 
		- Scripts to draw the paper figures 
3. Find a detailed documentation in the respective script and notebook


