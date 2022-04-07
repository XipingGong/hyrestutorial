#!/bin/bash
#SBATCH --job-name="ener"       # job name # XXX
#SBATCH --time=30-00:00:00       # time
#SBATCH --nodes=1              # number of nodes # XXX
#SBATCH --gres=gpu:4           # number of gpus per node
#SBATCH -p faster                # partition
#SBATCH -o job%j.log   # without -e, combine stdout/err
#SBATCH -e job%j.err

# @pikes, faster node
# -------------------
# GCC
module load gcc/6.1.0
export GCCTK=/cm/local/apps/gcc/6.1.0
export CC=$GCCTK/bin/gcc
export CXX=$GCCTK/bin/g++
# OPENMM
LOCAL=/home/ping/programs/openmm/build/7.5.0
export OPENMM_DIR=$LOCAL
export OPENMM_LIB_PATH=$LOCAL/lib
export OPENMM_INCLUDE_PATH=$LOCAL/include/
export OPENMM_PLUGIN_DIR=$LOCAL/lib/plugins
# CUDA
module load cuda/10.1.243
export CUDATK=/cm/shared/apps/cuda/10.1.243
export PATH=$CUDATK/lib64:$PATH
export PATH=$CUDATK/lib64/stubs:$PATH
export PATH=$CUDATK/bin:$PATH
export OPENMM_CUDA_COMPILER=$CUDATK/bin/nvcc

CHARMM='/home/ping/programs/charmm/build/hyres/charmm'
mpirun='/home/ping/programs/openmpi/openmpi-3.0.0/build/bin/mpirun'

# run
$CHARMM openmm=1 -i ener.inp > ener.1gpu.out
$CHARMM openmm=0 -i ener.inp > ener.1cpu.out
$mpirun -np 8 $CHARMM openmm=0 -i ener.inp > ener.8cpu.out

grep ' P53  ' ener.1gpu.out | awk '{print $1, $5, $6, $7}' | head -1775 > forces.1gpu.dat # natom = 1775
grep ' P53  ' ener.1cpu.out | awk '{print $1, $5, $6, $7}' | head -1775 > forces.1cpu.dat
grep ' P53  ' ener.8cpu.out | awk '{print $1, $5, $6, $7}' | head -1775 > forces.8cpu.dat

wait
