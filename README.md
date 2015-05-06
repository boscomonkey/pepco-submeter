# Forrestal Submeter Utility and Library #

The [Department of Energy](http://en.wikipedia.org/wiki/United_States_Department_of_Energy)'s main headquarters in Washington, DC is the [James V. Forrestal](http://en.wikipedia.org/wiki/James_V._Forrestal_Building) building. Inside the building are various energy usage meters that automatically gathers [submetering](http://en.wikipedia.org/wiki/Utility_submeter) data. These submetering [CSV](http://en.wikipedia.org/wiki/Comma-separated_values) files are structured to be human readable rather than machine readable. Here are command line scripts (in Ruby) to massage these CSV files into more machine readable form.

This code was developed to build a rich dataset for use at Department of Energy's [American Energy Data Challenge](http://energychallenge.energy.gov/).

## Execute the utility ##

After you clone this repository, change your working directory to it at the command line. From there, invoke the `format_matrix.rb` utility with the submetering CSV files and pipe the output to a file:

````
bin/format_matrix.rb forrestal1.csv forrestal2.csv forrestal3.csv > matrix.csv
````

The format_matrix.rb utility takes one or more CSV file arguments, and wildcards are accepted. Thus, the above command can be shortened to

````
bin/format_matrix.rb *.csv > matrix.csv
````

### CONSUMPTN ###

For each submetering point, there are two channels named *CONSUMPTN HI* and *CONSUMPTN LO*. The sum of these two channels is the cumulative energy consumption for the point in question. In order to determine the delta consumption (*CONSUMPTN*) for a point, we must subtract the cumulative energy consumption for the previous time period from the cumulative energy consumption for the current time period.

In order to do this, ````bin/format_matrix.rb```` opens the _previous_ CSV file, extracts the last time period from that file, and uses that data to compute *CONSUMPTN* for the first time period in the current set of files.

The ````bin/format_matrix.rb```` utility guesses the name of the previous file from the name of the first file (chronologically) in the current set of files. This assumes that the previous file is in the same directory as the current files. If not, it won't be found, and an empty value will be used for *CONSUMPTN* in the first time period.

You can explicitly specify the name of the _previous_ file with the ````-p```` option. For example:

````
bin/format_matrix.rb -p forrestal/201402/DEM_Report_02-28-14.csv forrestal/201403/*.csv
````

This processes all the CSV files in the ````forrestal/201403```` directory while using ````forrestal/201402/DEM_Report_02-28-14.csv```` as the _previous_ file. The ````-p```` option is necessary in this case because while the utility can guess the previous filename as ````DEM_Report_02-28-14.csv````, there is no reliable way to know that it is located in a different directory.


## Command Line Trick ##

Because the submetering data is spread out in 12 directories with one file per day, it's somewhat onerous to type all those directories explicitly as arguments. Fortunately, you can use the ````find```` command to grab all the CSV files and feed them as input to ````format_matrix.rb````.

If I unzip all the CSV tree into a directory named ````forrestal````, then the command looks like this:

````
find forrestal -type f -name '*.csv' | xargs bin/format_matrix.rb > 2014.csv
````

What this does is:

* find all the files under the ````forrestal```` directory with a name ending with ````.csv````
* feed those filenames as arguments to the ````format_matrix.rb```` utility
* capture the output of the utility as a file named ````2014.csv````
