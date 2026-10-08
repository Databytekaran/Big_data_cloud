# Big Data on Cloud - Modular Assignment 1
**Data Extraction, Data Processing and Knowledge Extraction** on the UCI Online Retail dataset - one integrated pipeline:

`UCI xlsx -> CSV -> S3 raw -> Glue job 1 (preprocess) -> S3 processed -> Glue job 2 (CDC simulation) -> S3 CDC zone -> Athena + Redshift -> Apriori -> Outliers + Similarity -> Report`

![architecture](architecture/architecture.png)

## Start here
| Want to... | Open |
|---|---|
| Read the results | `reports/final_report.md` (PDF: `reports/final_report.pdf`) |
| Understand how it was built | `docs/process_documentation.md` |
| Deploy on AWS | `docs/aws_deployment.md` and `aws/deploy_pipeline.sh` |
| See outlier + similarity code and output | `notebooks/outliers_and_similarity.ipynb` |

## Project structure
```
data/            convert_xlsx_to_csv.py, profile_raw.py   (raw/ processed/ cdc/ are generated, git-ignored)
glue/            preprocess_job.py (Glue job 1), cdc_job.py (Glue job 2)   - run on AWS Glue or local PySpark
cdc/             inspect_cdc.py  (sample outputs of the CDC simulation)
athena/          00_create_database_and_tables.sql, 01..06_*.sql, validate_locally.py, sample_outputs/
redshift/        01_create_schema_tables.sql, 02_copy_from_s3.sql, 03_validation_queries.sql, validate_locally.py
apriori/         run_apriori.py, load_baskets.py, apriori_scratch.py
notebooks/       outliers_and_similarity.ipynb   (executed, outputs included)
architecture/    architecture.png / .svg, build_diagram.py
aws/             deploy_pipeline.sh   (AWS CLI; not executed here)
reports/         final_report.md/.pdf, build_report.py, results/ (all numbers), figures/
docs/            process_documentation.md/.pdf, aws_deployment.md
run_local_pipeline.sh, requirements.txt, .gitignore
```

## Run locally (everything except the AWS services)
Needs Python 3.10+, Java 17+ (for PySpark) and `dot` (graphviz) for the diagram.
```bash
pip install -r requirements.txt
bash run_local_pipeline.sh /path/to/Online_Retail.xlsx
```
About 5 minutes (reading the 23 MB xlsx takes ~1 minute). Locally, PySpark replaces Glue and local Parquet folders replace S3; the job code is the same (`awsglue` is imported only if present).

## Assignment requirements -> implementation
| Assignment requirement | Implementation | File / folder |
|---|---|---|
| 1. Extract and preprocess with AWS Glue | PySpark Glue job: type cast, de-duplication, validation, reject log, DQ report | `glue/preprocess_job.py` |
| 2. CDC simulation (hint: versioned snapshots) | 3 snapshots, hash-based I/U/D change log, replay = current, verified | `glue/cdc_job.py`, `cdc/inspect_cdc.py` |
| 3. Query processed data with Athena | DDL + 19 queries (totals, revenue, customers, products, transactions, audit) | `athena/` |
| 4a. Load into Redshift | table with DISTKEY/SORTKEY, `COPY` from S3, views, validation queries | `redshift/` |
| 4b. Association rules with Apriori | mlxtend Apriori + from-scratch cross-check; support/confidence/lift | `apriori/` |
| 5a. Noise / outlier detection | Tukey IQR (log scale) + cancellation-reversal noise rule | `notebooks/outliers_and_similarity.ipynb` |
| 5b. Similarity / dissimilarity | Jaccard (customers), cosine (products), Euclidean (RFM) | same notebook |
| 6. Document pipeline and findings | process documentation, final report, architecture diagram | `docs/`, `reports/`, `architecture/` |

## Deliverables checklist
| Deliverable (assignment PDF) | Done | Evidence |
|---|---|---|
| Source code/scripts (Glue jobs, Athena queries, Apriori) | Yes | `glue/`, `athena/`, `apriori/` |
| Architecture diagram | Yes | `architecture/architecture.png` |
| Process documentation (PDF/Markdown) | Yes | `docs/process_documentation.md` (+ PDF) |
| Final report with insights from association rules | Yes | `reports/final_report.md` (+ PDF), sections 10 and 14 |
| Notebook/script for similarity + outlier detection | Yes | `notebooks/outliers_and_similarity.ipynb` |
| Presentation slides (optional) | Not created | optional in the assignment |

## Honest status
* **Executed and verified locally:** Glue jobs (PySpark), CDC, Athena SQL (on DuckDB), portable Redshift SQL (on DuckDB), Apriori, outliers, similarity, report.
* **Written but not executed (needs an AWS account):** running on Glue, Athena itself, Redshift DDL/`COPY`, `aws/deploy_pipeline.sh`, `--source redshift`.
* The CDC updates/deletes are **synthetic** (the UCI file is a static dump); this is a CDC *simulation*.
