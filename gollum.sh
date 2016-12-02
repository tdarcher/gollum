#!/bin/bash
#                    GOLLUM  the nemesis of SMEAGOL
#
# Gollum is a slum submission script to split a large job into several 
# 1 node jobs for high throughput calculations and small mpi taskfarming
# Written by Tom Archer  
######################################################################
#
# The job submitted to slum is flexable in size and duration 
# slum allows you to specify a range of wall times and nodes 
# so the script can take advantage of any sized gap in the queue
#
#SBATCH --nodes=1-4                                                        
#SBATCH -t 30:00 --time-min=10:00                                      
#SBATCH -p debug                                                          
############################################################################# 
# Gollum needs two variables should specify the variables: todo and EXE
# the "todo" directory  should contain a list of files starting with "xxxx" 
# e.g. xxxx0001 xxxx0002 xxxx0003 ...
# each file should contain the full path of the job you want to run
# EXE should be the executable you want to run e.g.
#
EXE="aims.071914_7.scalapack.mpi.x"
todo="$SLURM_SUBMIT_DIR/todo"
#
# enviromental setup for this build of fhi-aims
module purge
module load intel/14.0/composer_xe_2013_sp1.2.144  intel/14.0/impi-4.1.3.048
#
#
# No further customization is required below here
##############################################################################
ln -s $EXE EXE 2> /dev/null
run(){
    workdir=$SLURM_SUBMIT_DIR
    nnodes=`echo $SLURM_JOB_CPUS_PER_NODE | awk ' BEGIN {FS="("}{print $1}'`
    node=$1 
    echo $node
    # try to avoid race condition of all processors taking the same job
    t=`echo $1 | awk ' BEGIN { FS="-n" } {print $2} ' `
    sleep $t
    i=`ls $workdir/todo/*xxxx* 2> /dev/null | wc -l`
    while [ $i -gt 0 ] ; do
	cd $workdir/todo
	calculation=`ls  *xxxx* 2> /dev/null | head -n 1`
	dir=`cat $calculation`
	
##########   Run fhi-AIMS  ##################################################
	cd $dir
	rm -f $workdir/todo/$calculation                                                         
	echo "Running calculation " $dir " on node " $node
	mpiexec.hydra -bootstrap slurm -n $nnodes -hosts $node $workdir/EXE 2> err > OUT
#############################################################################
	i=`ls $workdir/todo/*xxxx*  2> /dev/null | wc -l`
	echo $i " calculations still to do "
    done
}
export -f run

scontrol show hostnames $SLURM_NODELIST | xargs -n 1 -P "$SLURM_NNODES" -i bash -c 'run "$@"' _ {} \
