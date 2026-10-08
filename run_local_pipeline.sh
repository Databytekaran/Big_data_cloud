#!/usr/bin/env bash
# Runs the whole pipeline on a laptop (PySpark local mode instead of Glue, local Parquet instead of S3).
# Requires Java 17+ for PySpark. Usage: bash run_local_pipeline.sh /path/to/Online_Retail.xlsx
set -euo pipefail
XLSX="${1:-Online_Retail.xlsx}"

mkdir -p data/raw reports/results reports/figures
python data/convert_xlsx_to_csv.py "$XLSX" data/raw/online_retail.csv     # 0. xlsx -> csv ("upload to S3 raw zone")
python data/profile_raw.py                                                # 1. profile raw data
python glue/preprocess_job.py --input_path data/raw --output_path data/processed   # 2. Glue job 1
python glue/cdc_job.py --input_path data/processed/clean --output_path data/cdc     # 3. Glue job 2 (CDC)
python cdc/inspect_cdc.py data/cdc | tee reports/results/cdc_sample_output.txt
python athena/validate_locally.py                                         # 4. Athena SQL checked on DuckDB
python redshift/validate_locally.py | tee reports/results/redshift_local_validation.txt   # 5. Redshift SQL (portable part)
python apriori/run_apriori.py | tee reports/results/apriori_run_log.txt   # 6. Apriori (+ cross-check)
jupyter nbconvert --to notebook --execute --inplace notebooks/outliers_and_similarity.ipynb   # 7. outliers + similarity
python architecture/build_diagram.py                                      # 8. diagram
python reports/build_report.py                                            # 9. report tables from the real results
