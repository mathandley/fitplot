
# fitplot 0.0.1
Plot your FitBit data!

## What does it do?
fitplot is a bash script for plotting FitBit Activities data exported from the 
FitBit Dashboard. It uses gawk/sed to clean the raw data from FitBit and gnuplot 
to plot the graphs.

## What I'm using it with

| My setup |                                                                                            |
|----------|--------------------------------------------------------------------------------------------|
| Hardware | MacBook Pro 2017                                                                           |
| OS       | MacOS High Sierra 10.13.2                                                                  |
| Terminal | Oh-My-Zsh 5.3                                                                              |
| Software | gawk 4.2.0, gnuplot 5.2 patchlevel 2, coreutils, other built-in tools e.g., sed, cat etc.  |

## How do you use it?
(1) Export an Activities report from https://www.fitbit.com/export/user/data as 
a csv. You can export up to 31 days of data at any one time. Selecting "Last 
month" is, therefore, a good place to start: 

<img src="Images/export.png" width="900">

(2) Execute fitplot on the downloaded csv file:

```bash
./fitplot fitbit_export_20180212.csv
```

(3) Three graphs will be generated: calories burned, steps taken, distance 
travelled. If you haven't modified the bash file, these will be saved in 
your working directory.

<img src="Images/calories.png" width="900">

Graphs include *mean* and *goal* values. The mean value is plotted as a black 
line and the top of the purple filled rectangle is the goal. For example, in 
the calories graph above, my goal is 3048 kcal/day, and my average for January 
was 2930 kcal/day. Goal values can be changed inside the script (see later).

## Bonus
The script also generates a csv file containing year-to-date data, which 
is updated each time you run fitplot on an exported csv file. You can plot 
year-to-date graphs using the `ytd` flag:

```bash
./fitplot --ytd=2018
```

The same three graphs will be generated, but this time they display year-to-date 
data:

<img src="Images/calories_ytd.png" width="900">

## How can I set my goals?
Edit the following variables in the script:

```bash
4: goalCals=3048    # kcal
5: goalSteps=10000    
6: goalDistance=8   # km
```

## Additional settings
The script needs a location to store output graphs and to maintain 
year-to-date csv files. I've set that to the working directory temporarily but 
please change it to a static location by amending the following variable:

```bash
13: outFP="./" 
```

The script also makes use of a single temporary file, which can be named 
anything you like so long as it's accessible. The temporary file is used when 
copying/sorting/making sense of the questionable csv formatting offered by
FitBit. Change the filepath if you wish by amending the following variable:

```bash
11: tmpFP="./fitplot.tmp" 
```

## Safety checks/validation
The script has practically no safety checking, so if you run fitplot on a csv 
file, make sure it's a valid *Activities* report exported from the FitBit 
Dashboard. *Don't* run it on a Body/Foods/Sleep report by accident like I did, 
because the output is weird and you'll mess up the corresponding year-to-date 
csv file. If you have accidentally run fitplot on the wrong csv file, you get 
*one* chance to restore your previous data from the `.old` file it creates in 
the output directory (i.e., the working directory if you've not modified the 
script).

## Changing the appearance of graphs
- Purple sucks!
- Why does each data point have its value stuck on top?
- That y-data should be plotted on a logarithmic scale goodness me.

Graphs are a personal thing, I know...

I've tried to make it as easy as possible for people to modify the appearance of
graphs by breaking down the gnuplots into components. The variables below 
correspond to the year-to-date calories burned graph. `calsTitle` is the
title of the graph. `calsGoal` is the purple rectangle representing the goal.
`calsLines` is the line connecting each data point. `calsPoints` is the set of
data points themselves along with their labels. `calsMean` is the black mean 
line:

```bash
193: calsTitle="Calories Burned $year"
194: calsGoal=..
195: calsLines=..
196: calsPoints=..
197: calsMean=..
```

Anyone wishing to change the appearance of graphs thus need only 
change/remove/add individual components. Ultimately some knowledge of bash and 
gnuplot is required, but StackOverflow has the answers (how do you think I came 
up with any of this in the first place?).

## Changing the size of graphs
To change the size of the graphs, amend the following lines:

```bash
125: set terminal png size 1680,1050  # size of monthly graphs
218: set terminal png size 1680,1050  # size of year-to-date graphs
```

At this point I have kept the monthly and year-to-date plotting implementations 
separate even though they are largely comparable. This is because I don't know 
how the year-to-date graphs will scale as more data is added. I presume the 
implementation will need altering in a month or two, so abstracting out 
functionality at this point is probably not the right move.

## Miscellaneous
- The script will delete the input csv file when it is executed.
- It doesn't matter if you run fitplot on the same data twice, the year-to-date 
file doesn't store duplicate entries.

## Made for MacOS (because that's what I use)
Linux/Unix users, I hope it's largely compatible, but I assume some of it won't 
be. Hopefully someone else can turn this into a Window's executable too.

## How I'm using it
Now I've set a static location for my output, I've copied the bash file to
`usr/local/bin` and made it executable. I now just run `fitplot.sh` from 
my downloads directory when I export an *Activities* report from the FitBit 
Dashboard. The script deletes the csv file so it leaves everything tidy.

## Questions/reviews
Feedback to martin.handley@nottingham.ac.uk :)

# Known Issues:
If users import monthly data spanning two separate years, e.g., mid December 
2017 to mid January 2018, the data will be put into the prior year's 
(i.e., 2017) year-to-date file.

## Disclaimer
Don't blame me for anything, especially if you're peeved at the shape of the
graphs :D.

DISCLAIMER OF WARRANTY

The Software is provided "AS IS" and "WITH ALL FAULTS," without warranty of any 
kind, including without limitation the warranties of merchantability, fitness 
for a particular purpose and non-infringement. The Licensor makes no warranty 
that the Software is free of defects or is suitable for any particular purpose. 
In no event shall the Licensor be responsible for loss or damages arising from 
the installation or use of the Software, including but not limited to any 
indirect, punitive, special, incidental or consequential damages of any character 
including, without limitation, damages for loss of goodwill, work stoppage, 
computer failure or malfunction, or any and all other commercial damages or 
losses. The entire risk as to the quality and performance of the Software is 
borne by you. Should the Software prove defective, you and not the Licensor 
assume the entire cost of any service and repair.





