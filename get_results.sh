workdir=`pwd`
for i in 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 ; do
    cd DB/$i
    E=`tail -n 100  OUT | awk '/Hartree-Fock s.c.f. calculation      :/{print $12}'`
    echo $i $E
    cd $workdir
done
