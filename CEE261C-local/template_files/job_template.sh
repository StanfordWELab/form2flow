#!/bin/bash
#SBATCH --job-name=class
#SBATCH --partition=serc
#SBATCH -n 32
#SBATCH --time=12:00:00
#SBATCH --constraint="[CLASS:SH3_CBASE|CLASS:SH3_CBASE.1|CPU_GEN:SKX]"
# #SBATCH --mem=72G
# #SBATCH -N 2

module purge

module load system
module load libpng/1.2.57
module load openmpi/4.1.2


#RUN STITCH
srun /home/groups/gorle/codes/cascade-master-openmpi4/bin/stitch.exe -i stitch_file.in > stitch.log
srun /home/groups/gorle/codes/cascade-master-openmpi4/src/charles/charles_helm.exe -i charles_file.in > charles.log
