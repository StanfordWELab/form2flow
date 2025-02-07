#!/bin/bash
#SBATCH --job-name={SUID}-WW
#SBATCH --partition=serc
#SBATCH -N 1
#SBATCH -n 32
#SBATCH --time=12:00:00
#SBATCH --constraint="[CLASS:SH3_CBASE|CLASS:SH3_CBASE.1|CPU_GEN:SKX]"
#SBATCH --mail-user={SUID}@stanford.edu
#SBATCH --mail-type=ALL

# #SBATCH --mem=72G

module purge

module load system
module load libpng/1.2.57
module load openmpi/4.1.2


#RUN STITCH
srun /home/groups/gorle/codes/cascade-master-openmpi4/bin/stitch.exe -i stitch_file.in > stitch.log
srun /home/groups/gorle/codes/cascade-master-openmpi4/src/charles/charles_helm.exe -i charles_file.in > charles.log

touch createVideos2.tmp