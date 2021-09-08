# Find commits

run `git log -100 --pretty=format:"%h; %cd; %s"` to get a list of the last 100 commits in a cloned (e.g., influxDB) repositoy.

# Write commits in file

run `git log -100 --pretty=format:"%h; %cd; %s" > commits.csv` to create a file with the recent 100 commits.

# Open the csv file and transform it (e.g., using Excel) into a for our tool parseable format

see, e.g., commitTable_Influx.csv to get an example

Format:
`number (recent commits at the top); version1 hash (new); version2 hash (old); date (optional, for debugging); subject (optional, for debugging)`
 
