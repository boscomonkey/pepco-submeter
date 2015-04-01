# Pepco Submeter Ruby Utility and Library

Green Button submetering CSV files from [Pepco Electric Utility](http://www.pepco.com/) are structured to be human readable rather than machine readable. Here are command line scripts to massage these CSV files into more machine readable form.

This code was developed to build a rich dataset for use at Department of Energy's American Energy Data Challenge.

###Grab the code from github

At the command line, issue this command:

````
git clone git@github.com:boscomonkey/pepco-submeter.git
````

This will create a copy of the code base in a subdirectory named `pepco-submeter`.

###Execute the utility

At the command line, change your working directory to `pepco-submeter`

````
cd pepco-submeter
````

Invoke the `format_matrix.rb` utility with the submetering CSV files and pipe the output to a file:

````
./format_matrix.rb pepco1.csv pepco2.csv pepco3.csv > matrix.csv
````

The format_matrix.rb utility takes one or more CSV file arguments, and wildcards are accepted. Thus, the above command can be shortened to

````
./format_matrix.rb *.csv > matrix.csv
````

###Command Line Trick

Because the submetering data is spread out in 12 directories with one file per day, it's somewhat onerous to type all those directories explicitly as arguments. Fortunately, you can use the ````find```` command to grab all the CSV files and feed them as input to ````format_matrix.rb````.

If I unzip all the CSV tree into a directory named ````pepco````, then the command looks like this:

````
find pepco -type f -name '*.csv' | xargs ./format_matrix.rb > 2014.csv
````

What this does is:

* find all the files under the ````pepco```` directory with a name ending with ````.csv````
* feed those filenames as arguments to the ````format_matrix.rb```` utility
* capture the output of the utility as a file named ````2014.csv````
