from pathlib import Path
import yaml
import shutil


checkpoint clone_basepipeline:
    output:
        directory('single-point-analysis-pipeline'),
        scripts_symlink=directory('workflow/scripts')
    params:
        configfile='single-point-analysis-pipeline/config.yaml',
        basepipeline_snakefile='single-point-analysis-pipeline/workflow/Snakefile',
        basepipeline_scripts_dir='single-point-analysis-pipeline/workflow/scripts'
    shell: '''
        git clone https://github.com/hmgu-itg/single-point-analysis-pipeline.git
        ln -s $(realpath {params.basepipeline_scripts_dir}) {output.scripts_symlink}
    '''


rule pull_container:
    input:
        lambda w: checkpoints.clone_basepipeline.get().rule.params.configfile
    shell: '''
        URI=$(grep -o '"[^"]*"' {input} | grep "{params}" | sed 's/^"//;s/"$//')
        if command -v apptainer &> /dev/null; then
            # apptainer is available
            apptainer pull {output} $URI
        else
            # apptainer not found, fall back to singularity
            singularity pull {output} $URI
        fi
    '''


use rule pull_container as pull_main_container with:
    params: 'hmgu-itg/single-point-analysis-pipeline'
    output: 'containers/single-point-analysis-pipeline.sif'

use rule pull_container as pull_peakplotter_container with:
    params: 'hmgu-itg/default/peakplotter'
    output: 'containers/peakplotter.sif'

use rule pull_container as pull_manqq_container with:
    params: 'hmgu-itg/default/manqq'
    output: 'containers/manqq.sif'


rule create_base_config:
    input:
        orig_configfile=lambda w: checkpoints.clone_basepipeline.get().rule.params.configfile,
        main_container=rules.pull_main_container.output[0],
        pp_container=rules.pull_peakplotter_container.output[0],
        manqq_container=rules.pull_manqq_container.output[0]
    output:
        'config-base.yaml'
    run:
        shutil.copy(input.orig_configfile, output[0])
        with open(output[0], 'r') as f:
            config = yaml.safe_load(f)
        
        with open(output[0], 'r') as f:
            content = f.read()

        main_url = config['container']['all']
        pp_url = config['container']['peakplotter']
        manqq_url = config['container']['manqq']
        modified_content = content.replace(main_url, str(Path(input.main_container).resolve()))
        modified_content = modified_content.replace(pp_url, str(Path(input.pp_container).resolve()))
        modified_content = modified_content.replace(manqq_url, str(Path(input.manqq_container).resolve()))
        with open(output[0], 'w') as f:
            f.write(modified_content)
