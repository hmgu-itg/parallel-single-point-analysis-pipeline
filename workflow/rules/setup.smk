from pathlib import Path
import yaml
import shutil


rule clone_basepipeline:
    output:
        configfile='single-point-analysis-pipeline/config.yaml',
        basepipeline_snakefile='single-point-analysis-pipeline/workflow/Snakefile'
    shell: '''
        git clone https://github.com/hmgu-itg/single-point-analysis-pipeline.git
    '''


rule pull_container:
    input:
        rules.clone_basepipeline.output.configfile
    shell: '''
        URI=$(grep -o '"[^"]*"' {input} | grep "{params}")
        apptainer pull {output} $URI 
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
        orig_configfile=rules.clone_basepipeline.output.configfile,
        main_container=rules.pull_main_container.output,
        pp_container=rules.pull_peakplotter_container.output,
        manqq_container=rules.pull_manqq_container.output
    output:
        'config-base.yaml'
    run:
        shutil.copy(input.orig_configfile, output[0])
        with open(output[0], 'r') as f:
            config = yaml.safe_load(f)
            content = f.read()

        main_url = config['container']['all']
        pp_url = config['container']['peakplotter']
        manqq_url = config['container']['manqq']

        modified_content = content.replace(main_url, Path(input.main_container).resolve())
        modified_content = modified_content.replace(pp_url, Path(input.pp_container).resolve())
        modified_content = modified_content.replace(manqq_url, Path(input.manqq_container).resolve())

        with open('config-base.yaml', 'w') as f:
            f.write(modified_content)
