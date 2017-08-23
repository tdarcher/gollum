#!/bin/bash
#           Mairon the corrupter of men of the Middle Earth
#
# Mairon is a slum submission script to split a large job into several 
# multi node jobs for high throughput calculations and small mpi taskfarming
# originally written for jobs that cannot be run on 1 node. 
# WARNING : It is always efficient to run large number of jobs on single node
# using the origilnal gollum script
# Gollum script Written by Tom Archer
# editted to its current form by Urvesh Patil
#############################################################################
#
#
# The job submitted to slum is flexable in  duration 
# slum allows you to specify a range of wall times
# In the current form variable nodes are not supported 
# so the script can take advantage of any sized gap in the queue
#
#SBATCH --nodes=4                                                        
#SBATCH -t 30:00 --time-min=10:00                                      
#SBATCH -p debug                                                          
############################################################################# 
# Mairon needs three variables should specify the variables: todo, EXE and Noption
# the "todo" directory  should contain a list of files starting with "xxxx" 
# e.g. xxxx0001 xxxx0002 xxxx0003 ...
# each file should contain the full path of the job you want to run
# EXE should be the executable you want to run e.g.
#number of nodes used per calculation specified by Noption
#
export EXE="/home/users/patilu/bin/parsons/vasp_gam"
export todo="$SLURM_SUBMIT_DIR/todo"
export Noption=2
# enviromental setup for this build of VASP
module purge
module load intel/15.0.6/composer_xe_2015.6.233 intel/15.0.6/impi-5.0.3.049
#
# No further customization is required below here
##############################################################################
run(){
    workdir=$SLURM_SUBMIT_DIR
    # MPIoption is the variable which calculates the -n argument (number of nodes * number of cpu per nodes)
    nnodes=`echo $SLURM_JOB_CPUS_PER_NODE | awk ' BEGIN {FS="("}{print $1}'`
    MPIoption=$((Noption*nnodes))
    # replace spaces by commas to create a comma seperated nodelist
    nlist=`echo $1 | sed 's/ /,/g'`

    # try to avoid race condition of all processors taking the same job
    t=`echo $1 | awk ' BEGIN { FS="-n" } {print $2} ' | awk ' BEGIN { FS=" " } {print $1} '`
    echo "t=" $t
    sleep $t

    i=`ls $workdir/todo/*xxxx* 2> /dev/null | wc -l`
    while [ $i -gt 0 ] ; do
	cd $workdir/todo
	calculation=`ls  *xxxx* 2> /dev/null | head -n 1`
	dir=`cat $calculation`
	
##########   Run fhi-AIMS  ##################################################
	cd $dir
	rm -f $workdir/todo/$calculation                                                         
	echo "Running calculation " $dir " on nodes  " $nlist
	mpiexec.hydra -bootstrap slurm -n $MPIoption --host $nlist $EXE 2> err > OUT
#############################################################################
	i=`ls $workdir/todo/*xxxx*  2> /dev/null | wc -l`
	echo $i " calculations still to do "
    done
}
export -f run

nodelist=`srun hostname -s | sort | uniq`
numProc=$((SLURM_JOB_NUM_NODES/Noption))

echo number of parallel processes = $numProc
echo nodes allocated : $nodelist

echo $nodelist | xargs -d' ' -n $Noption | xargs -n 1 -P $numProc -i bash -c 'run "$@"' _ {} \
