#!/bin/bash

startime=$(date + %S)

echo "script executed at $startime"

sleep=10

endtime=$(date + %S)
 
total_time=(($endtime-$startime))

echo "script excuted in $total_time"