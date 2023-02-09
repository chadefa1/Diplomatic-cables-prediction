#!/bin/bash

# Start counting execution time
start=$(date +%s.%N)

pip3 install -r requirements.txt
echo "Requirements met"
python3 ./topic_models/run_nmf_cables.py
python3 ./topic_models/run_nmf_newspaper.py
Rscript ./topic_models/Figure1_appendix.R
Rscript ./topic_models/Figure1_paper.R
Rscript ./topic_models/Figure2_paper.R
Rscript -e "rmarkdown::render('Forecasting_Replication/predictionReplication_notebook.Rmd')"

# Print execution time
sleep 5
duration=$(echo "$(date +%s.%N) - $start" | bc)
execution_time=`printf "%.2f seconds" $duration`
echo "Script Execution Time: $execution_time"
