tot=`cat $1 | cut -d' ' -f2 | xargs | tr ' ' '+' | bc -l | xargs | tr ' ' '+' | bc -l`
echo $tot/3600 | bc -l
