#!/bin/bash
#SBATCH --job-name={SUID}-WW
#SBATCH --partition=serc
#SBATCH -N 1
#SBATCH -n 32
#SBATCH --time=96:00:00
#SBATCH --constraint="[CLASS:SH3_CBASE|CLASS:SH3_CBASE.1|CPU_GEN:SKX]"
#SBATCH --mail-user={SUID}@stanford.edu
#SBATCH --mail-type=ALL

# #SBATCH --mem=72G

source ../../../../cascade_reference.sh

#RUN STITCH
mpiexec -- "$CASCADE_DIR/src/stitch/stitch.exe" -i stitch_file.in > stitch_out.txt
mpiexec -- "$CASCADE_DIR/src/charles/charles_helm.exe" -i charles_file.in > charles_out.txt

touch createVideos2.tmp