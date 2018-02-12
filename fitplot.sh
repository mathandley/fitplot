
# Settings ---------------------------------------------------------------------

# User goals.
goalCals=3042    # kcal
goalSteps=10000    
goalDistance=5   # km

# Filepaths.
# Needed when cleaning up the raw data from FitBit and appending monthly data to yearly data.
tmpFP="./fitplot.tmp" 
# Output data/graphs stored in this folder.
outFP="/Users/martinathandley/Documents/Coding/FitBit/Output/"         

# Constants.
dates=( ["10#01"]="January" ["10#02"]="February" ["10#03"]="March" 
        ["10#04"]="April"   ["10#05"]="May"      ["10#06"]="June" 
        ["10#07"]="July"    ["10#08"]="August"   ["10#09"]="September" 
        ["10#10"]="October" ["10#11"]="November" ["10#12"]="December" )

# Functions --------------------------------------------------------------------

# Monthly usage.
monthly()
{
  echo "Generating monthly graphs."
  # From now on we blindly assume the file given is the one as described in the 
  # introduction.

  # Cleaning up the raw data:
  # (0) Drop the two header rows.
  # (1) Only take first 4 fields (date, calories, steps, distance).
  # (2) Remove quotes from date and distance, e.g., "04-01-2018" -> 04-01-2018.
  # (3) Convert FitBit's crappy string-comma-number format to actual numbers,
  #     e.g., "1,807" -> 1807.
  # Note we use a temporary file for intermittent results.
  sed '/^$/d' $1 \
  | gawk 'BEGIN{FPAT="([^,]+)|(\"[^\"]+\")"; OFS=" "} NR>2{print $1,$2,$3,$4}' \
  | gawk 'function GETINT ( F ) {gsub(/[^0-9]/,"",$F)} ;\
         function RMVQS ( F ) {gsub(/[\"]/,"",$F)} ;\
         {RMVQS(1); GETINT(2) ; GETINT(3); RMVQS(4) ; print $1, \
         $2, $3, $4}' > $tmpFP

  # Store result in original file.
  cat $tmpFP > $1 
  rm $tmpFP

  # Append monthly data to yearly data.
  year=$(date +"%Y")
  yearOut=$outFP$year".csv"
  cat $1 >> $yearOut
  # Remove any duplicates and sort by date (by year, month, day).
  sort -u -b -k 1.7,1.10 -k 1.4,1.5 -k 1.1,1.2 $yearOut > $tmpFP
  cat $tmpFP > $yearOut
  rm $tmpFP

  # Project information from input file.
  # Date range.
  minDate=$(gawk 'BEGIN{FS=" "} {print $1}' $1 | sort    | head -1)             
  maxDate=$(gawk 'BEGIN{FS=" "} {print $1}' $1 | sort -r | head -1)
  read -r month <<<$(gawk 'BEGIN{FS="-"} {print $2}' <<< $minDate)
  # Month name for graphs.
  monthName=${dates[10#$month]}

  # Graph filepaths.
  calsGraphOut=$outFP"Calories_"$month"_"$year".png"
  stepsGraphOut=$outFP"Steps_"$month"_"$year".png"
  distanceGraphOut=$outFP"Distance_"$month"_"$year".png"

  # Calculate monthly averages.
  read -r meanCals meanSteps meanDistance <<<$(awk 'BEGIN{FS=" "} \
   NR>1{totCals+=$2; totSteps+=$3; totDistance+=$4} END{print totCals/(NR-1) \
   " " totSteps/(NR-1) " " totDistance/(NR-1)}' $1)

  # gnuplot components.
  # Calories.
  calsTitle="Calories Burned $monthName $year"
  calsGoal="$goalCals with filledcurves below x1 linecolor rgb \"blue\" title \"Goal: $goalCals\""
  calsLines="'$1' using 1:2 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  calsPoints="'$1' using 1:2:2 with labels offset char .5,.5 font \",10\" title \"\""
  calsMean="$meanCals with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanCals\""
  # Steps.
  stepsTitle="Steps Taken $monthName $year"
  stepsGoal="$goalSteps with filledcurves below x1 linecolor rgb \"blue\" title \"Gaol: $goalSteps\""
  stepsLines="'$1' using 1:3 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  stepsPoints="'$1' using 1:3:3 with labels offset char .5,.5 font \",10\" title \"\""
  stepsMean="$meanSteps with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanSteps\""
  # Distance.
  distanceTitle="Distance Travelled $monthName $year"
  distanceGoal="$goalDistance with filledcurves below x1 linecolor rgb \"blue\" title \"Goal: $goalDistance\""
  distanceLines="'$1' using 1:4 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  distancePoints="'$1' using 1:4:4 with labels offset char .5,.5 font \",10\" title \"\""
  distanceMean="$meanDistance with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanDistance\""

  # Plot graphs with gnuplot.
  gnuplot -persist <<-EOFMarker
    unset multiplot
    set datafile separator ' '
    set terminal png size 1680,1050
    set style fill transparent solid 0.02 noborder
    set timefmt "%d-%m-%Y"
    set autoscale y
    set xrange ["$minDate":"$maxDate"]
    set xlabel "Date"

    set ylabel "Calories (kcal)"
    set title "$calsTitle" offset 0,-0.5
    set output "$calsGraphOut"
    plot $calsGoal, $calsLines, $calsPoints, $calsMean

    set ylabel "Steps"
    set title "$stepsTitle" offset 0,-0.5
    set output "$stepsGraphOut"
    plot $stepsGoal, $stepsLines, $stepsPoints, $stepsMean

    set ylabel "Distance (km)"
    set title "$distanceTitle" offset 0,-0.5
    set output "$distanceGraphOut"
    plot $distanceGoal, $distanceLines, $distancePoints, $distanceMean
EOFMarker

  # Delete input file.
  rm $1

  # Open graphs.
  open $distanceGraphOut $stepsGraphOut $calsGraphOut
}

# Year-to-date usage.
ytd()
{
  year=$(date +"%Y")
  yearOut=$outFP$year".csv"

  # Check year-to-date file exists.
  if [ ! -f $yearOut ]
    then 
      echo "Error: no year-to-date data."
      echo "Path searched: $yearOut."
      echo "For monthly graphs use: fitplot.sh <input file>."
      exit 1
  fi

  echo "Generating year-to-date graphs."
  # From now on we blindly assume the file given is the one as described in the 
  # introduction.

  # Make sure file is sorted correctly.
  sort -b -k 1.7,1.10 -k 1.4,1.5 -k 1.1,1.2 $yearOut > $tmpFP
  cat $tmpFP > $yearOut
  rm $tmpFP

  # Project information from input file.
  # Date range.
  minDate=$(gawk 'BEGIN{FS=" "} {print $1}' $yearOut | head -1)             
  maxDate=$(gawk 'BEGIN{FS=" "} {print $1}' $yearOut | sort -r -b -k 1.7,1.10 -k 1.4,1.5 -k 1.1,1.2 | head -1)

  # Graph filepaths.
  calsGraphOut=$outFP"Calories_"$year".png"
  stepsGraphOut=$outFP"Steps_"$year".png"
  distanceGraphOut=$outFP"Distance_"$year".png"

  # Calculate monthly averages.
  read -r meanCals meanSteps meanDistance <<<$(awk 'BEGIN{FS=" "} \
   NR>1{totCals+=$2; totSteps+=$3; totDistance+=$4} END{print totCals/(NR-1) \
   " " totSteps/(NR-1) " " totDistance/(NR-1)}' $yearOut)

  # gnuplot components.
  # Calories.
  calsTitle="Calories Burned $year"
  calsGoal="$goalCals with filledcurves below x1 linecolor rgb \"blue\" title \"Goal: $goalCals\""
  calsLines="'$yearOut' using 1:2 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  calsPoints="'$yearOut' using 1:2:2 with labels offset char .5,.5 font \",10\" title \"\""
  calsMean="$meanCals with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanCals\""
  # Steps.
  stepsTitle="Steps Taken $year"
  stepsGoal="$goalSteps with filledcurves below x1 linecolor rgb \"blue\" title \"Goal: $goalSteps\""
  stepsLines="'$yearOut' using 1:3 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  stepsPoints="'$yearOut' using 1:3:3 with labels offset char .5,.5 font \",10\" title \"\""
  stepsMean="$meanSteps with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanSteps\""
  # Distance.
  distanceTitle="Distance Travelled $year"
  distanceGoal="$goalDistance with filledcurves below x1 linecolor rgb \"blue\" title \"Goal: $goalDistance\""
  distanceLines="'$yearOut' using 1:4 title \"\" with linespoints lw 2 pt 5 ps 0.5 linecolor rgb \"#E5CCFF\""
  distancePoints="'$yearOut' using 1:4:4 with labels offset char .5,.5 font \",10\" title \"\""
  distanceMean="$meanDistance with lines lw 1.5 linecolor rgb \"black\" title \"Avg.: $meanDistance\""

  # Plot graphs with gnuplot.
  gnuplot -persist <<-EOFMarker
    unset multiplot
    set datafile separator ' '
    set terminal png size 1680,1050
    set style fill transparent solid 0.02 noborder
    set timefmt "%d-%m-%Y"
    set xdata time
    set format x "%d-%m"
    set autoscale y
    set xrange ["$minDate":"$maxDate"]
    set xlabel "Date"

    set ylabel "Calories (kcal)"
    set title "$calsTitle" offset 0,-0.5
    set output "$calsGraphOut"
    plot $calsGoal, $calsLines, $calsPoints, $calsMean

    set ylabel "Steps"
    set title "$stepsTitle" offset 0,-0.5
    set output "$stepsGraphOut"
    plot $stepsGoal, $stepsLines, $stepsPoints, $stepsMean

    set ylabel "Distance (km)"
    set title "$distanceTitle" offset 0,-0.5
    set output "$distanceGraphOut"
    plot $distanceGoal, $distanceLines, $distancePoints, $distanceMean
EOFMarker

  # Open graphs.
  open $distanceGraphOut $stepsGraphOut $calsGraphOut
}

# Top-level.
main()
{
  # Check number of arguments.
  if [ "$#" -ne 1 ]
    then 
      echo "Error: incorrect number of arguments specified."
      echo "For monthly graphs use: fitplot.sh <input file>."
      echo "For year-to-date graphs use: fitplot.sh --ytd."
      exit 1
  fi

  # Script usage.
  if [ "$1" == "--ytd" ] 
    then ytd
  # Check file exists and that it has a .csv extension.
  elif [ -f $1 ] && [ ${1: -4} == ".csv" ]
    then monthly $1
  else
    echo "Error: invalid usage argument."
    echo "For monthly graphs use: fitplot.sh <input file>."
    echo "For year-to-date graphs use: fitplot.sh --ytd."
  fi
}

# Entry point ------------------------------------------------------------------

# Run top-level with all command line arguments.
main $@