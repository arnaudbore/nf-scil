
process PREPROC_TOPUP {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_1.6.0.sif':
        'scilus/scilus:1.6.0' }"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec), path(b0), path(rev_dwi), path(rev_bval), path(rev_bvec), path(rev_b0)
        path(config_topup)

    output:
        tuple val(meta), path("*__corrected_b0s.nii"), emit: topup_corrected_b0s
        tuple val(meta), path("*_fieldcoef.nii"), emit: topup_fieldcoef
        tuple val(meta), path("*_movpar.txt"), emit: topup_movpart
        tuple val(meta), path("*__rev_b0_warped.nii.gz"), emit: rev_b0_warped
        tuple val(meta), path("*__rev_b0_mean.nii.gz"), emit: rev_b0_mean
        tuple val(meta), path("*__b0_mean.nii.gz"), emit: b0_mean
        path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def prefix_topup = task.ext.prefix_topup ? task.ext.prefix_topup : ""
    def config_topup = config_topup ?: task.ext.default_config_topup
    def encoding = task.ext.encoding ? task.ext.encoding : ""
    def readout = task.ext.readout ? task.ext.readout : ""
    def b0_thr_extract_b0 = task.ext.b0_thr_extract_b0 ? task.ext.b0_thr_extract_b0 : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234
    export FSLOUTPUTTYPE=NIFTI

    if [[ -f "$b0" ]];
    then
        scil_image_math.py concatenate $b0 $b0 ${prefix}__concatenated_b0.nii.gz
        scil_image_math.py mean ${prefix}__concatenated_b0.nii.gz ${prefix}__b0_mean.nii.gz
    else
        scil_extract_b0.py $dwi $bval $bvec ${prefix}__b0_mean.nii.gz --mean --b0_thr $b0_thr_extract_b0 --force_b0_threshold
    fi

    if [[ -f "$rev_b0" ]];
    then
        scil_image_math.py concatenate $rev_b0 $rev_b0 ${prefix}__concatenated_rev_b0.nii.gz
        scil_image_math.py mean ${prefix}__concatenated_rev_b0.nii.gz ${prefix}__rev_b0_mean.nii.gz
    else
        scil_extract_b0.py $rev_dwi $rev_bval $rev_bvec ${prefix}__rev_b0_mean.nii.gz --mean --b0_thr $b0_thr_extract_b0 --force_b0_threshold
    fi

    antsRegistrationSyNQuick.sh -d 3 -f ${prefix}__b0_mean.nii.gz -m ${prefix}__rev_b0_mean.nii.gz -o output -t r -e 1
    mv outputWarped.nii.gz ${prefix}__rev_b0_warped.nii.gz
    scil_prepare_topup_command.py ${prefix}__b0_mean.nii.gz ${prefix}__rev_b0_warped.nii.gz\
        --config $config_topup\
        --encoding_direction $encoding\
        --readout $readout --out_prefix $prefix_topup\
        --out_script
    sh topup.sh
    cp corrected_b0s.nii ${prefix}__corrected_b0s.nii

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 1.6.0
        antsRegistration: 2.4.3
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')

    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_image_math.py -h
    scil_extract_b0.py -h
    antsRegistrationSyNQuick.sh -h
    scil_prepare_topup_command.py -h

    touch ${prefix}__corrected_b0s.nii
    touch ${prefix}__rev_b0_warped.nii.gz
    touch ${prefix}__rev_b0_mean.nii.gz
    touch ${prefix}__b0_mean.nii.gz
    touch ${prefix_topup}_fieldcoef.nii
    touch ${prefix_topup}_movpar.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 1.6.0
        antsRegistration: 2.4.3
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')

    END_VERSIONS
    """
}
