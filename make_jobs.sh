workdir=`pwd`
mkdir DB 2> /dev/null
mkdir todo 2> /dev/null

for i in 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 ; do
    echo "DB/$i"
    cp -r template DB/$i
    cd DB/$i
    sed "s/xxxx/$i/g" geometry.in > tmp
    mv tmp geometry.in
    new_job_number=`ls $workdir/todo/*xxxx*  | sort | tail -n 1 | awk 'BEGIN { FS = "xxxx" } ; {printf "%.8d",$2+1} ' `
    job_number="$workdir/todo/xxxx$new_job_number"
    test=`grep "$i" $workdir/todo/*`
    if [[ -z $test ]] ; then
        pwd > $job_number
    fi
    cd $workdir
done
