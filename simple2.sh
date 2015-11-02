echo starting prep!
output=$(sbatch --job-name="sleepy" \
        --partition=gpu \
        --gres=gpu:k20x:1 \
        --mail-type=END \
        --workdir=`pwd` \
        ~/bin/sleepy.sh)
prep_job=$(echo $output | cut -f4 -d' ')
echo prep finished

