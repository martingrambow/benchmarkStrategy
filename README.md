


# Howto run the experiments and reproduce the results (e.g., for InfluxDB):

## General setup
1. Clone this project

``` git clone ... ```


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

1. Navigate to the application benchmark folder of the respective system
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
3. Start the application benchmark using the main.sh script and three arguments:
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
3. Transform pprof profiles to dot files (optional)
	1. Clone the gocg tool: https://bitbucket.org/sealuzh/gocg/src/master/
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

# How to analyze the results

1. Open the analyis folder as a Pycharm project
2. Find a detailed documentation in the respective script and notebook


