# Parallel single-point-analysis-pipeline
This is a pipeline to run the [single-point-analysis-pipeline](https://github.com/hmgu-itg/single-point-analysis-pipeline) for multiple phenotypes in parallel.  


## Setup
```bash
snakemake --cores 5 config-base.yaml
```
This command needs to run first to setup the parallel pipeline.  
This will include cloning the [single-point-analysis-pipeline repository](https://github.com/hmgu-itg/single-point-analysis-pipeline), pulling all the containers, and generating the `config-base.yaml` file.


## Run

### `config-base.yaml`
The contents of this file will be used as the base configuration for all your runs.  
You will need to set the path for the `bfile`, `lmiss`, a `grm` configurations.  
Please refer to the [README of the single-point-analysis-pipeline](https://github.com/hmgu-itg/single-point-analysis-pipeline/blob/master/README.md) for more details. 

### Sample sheet list
The user must prepare a `.csv` file and place it inside the `outputs` directory.  
The `.csv` file must have the following columns:
- `id`: A unique identifier which will be used as the directory name to store all the output files of the `single-point-analysis-pipeline` run.
- `phenotype_file`: Path to the phenotype file to run the single-point association analysis.

If you wish to configure different configuration values for individual jobs, you may add columns that corresponds to the configuration values used in the `config-base.yaml` file.  
For example, if you wish to set a different p-value threshold for different phenotype jobs, you may add a `p-value` column and set the different thresholds for each run/rows.  

Please refer to the `outputs/example.csv` file.

### Command
```bash
snakemake \
  --config \
    jobs=20 \
    mem_mb=2000000 \
    singularity-args="" \
  --cores 200 \
  --keep-going \
  --dry-run \
  outputs/example/.done
```

Configuration values set in the above example command is only for demonstration purposes. Please set the numbers according to your own environment.  
Note, the tree between `outputs` and `.done` (i.e. `example`), will be treated as a wildcard and needs to match your sample sheet list filename.  
For example, if you have created the sample sheet at `outputs/myrun.csv`, then you need to run the snakemake command with the target as `outputs/myrun/.done`.  

You can place your sample sheet file in a deeper tree if you wish. For example, you can place your sample sheet file in `outputs/cohort-name/group1.csv` and the parallel pipeline with `outputs/cohort-name/group1/.done` as the target.

**Configuration:**
- `jobs`: Maximum number of `single-point-analysis-pipeline` jobs to run in parallel at the time
- `mem_mb`: Total number of memory in megabytes to use. This total memory will be divided by the number of `jobs`, and each job will use the divided amount of memory to run the job
- `singularity-args`: Any arguments needed to pass onto `singularity`. Please see [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executing/cli.html#snakemake.cli-get_argument_parser-apptainer/singularity)
- `cores`: The total number of cores to use. This total core will be divided by the number of `jobs`, and each job will use the divided number of cores to run the job