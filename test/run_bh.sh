#!/bin/bash
#SBATCH --time=15:00
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --hint=compute_bound

. /etc/bashrc

export RUSTFLAGS="-L/opt/ohpc/pub/libs/hwloc/lib -C link-arg=-Wl,-rpath,/opt/ohpc/pub/libs/hwloc/lib"

output_file_seq="AA_SLURM_OUT/BH/outseq.$SLURM_JOB_ID"
output_file_ran="AA_SLURM_OUT/BH/outrandom.$SLURM_JOB_ID"
output_file_topo="AA_SLURM_OUT/BH/outtopo.$SLURM_JOB_ID"
output_file_stealback="AA_SLURM_OUT/BH/outstealback.$SLURM_JOB_ID"
output_file_hashing="AA_SLURM_OUT/BH/outhashing.$SLURM_JOB_ID"
output_file_priority="AA_SLURM_OUT/BH/outpriority.$SLURM_JOB_ID"
output_file_registry="AA_SLURM_OUT/BH/outregistry.$SLURM_JOB_ID"
output_file_mugging="AA_SLURM_OUT/BH/outmugging.$SLURM_JOB_ID"
output_file_stealbackmugging="AA_SLURM_OUT/BH/outstealbackmugging.$SLURM_JOB_ID"



dump_file="AA_SLURM_OUT/BH/err.$SLURM_JOB_ID"


input_file="/var/scratch/abliokou/bh_data/two_plummers_1M.txt"
output="AA_SLURM_OUT/BH/output.$SLURM_JOB_ID"

echo "Saving logs to $output_file"
echo "version,num_workers,time_secs" > $output_file

executabe_file="./target/release/bh"

N=5


if [ "$1" = "seq" ]; then
    echo "version,num_workers,time_secs" > $output_file_seq
    VERSION="seq"



    cargo build --release -p bh
    for iter in {1..6}; do
        $executabe_file seq $input_file $output $N  2>> $dump_file >> $output_file_seq
    done


fi 

if [ "$1" = "random" ]; then

    VERSION="random"
    echo "version,num_workers,time_secs" > $output_file_ran

    cargo build --release --no-default-features --features "safe" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file" >> $output_file_ran
        done
    done

fi

if [ "$1" = "priority" ]; then

    VERSION="priority"
    echo "version,num_workers,time_secs" > $output_file_priority

    cargo build --release --no-default-features --features "safe priority" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file" >> $output_file_priority
        done
    done

fi

if [ "$1" = "registry" ]; then

    VERSION="registry"
    echo "version,num_workers,time_secs" > $output_file_registry

    cargo build --release --no-default-features --features "safe register" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers
       
        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file" >> $output_file_registry
        done
    done

fi



if [ "$1" = "topo" ]; then

    VERSION="topology"
    echo "version,num_workers,time_secs" > $output_file_topo


    cargo build --release --no-default-features --features "safe topology" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file" >> $output_file_topo
        done
    done

fi

if [ "$1" = "stealback" ]; then

    echo "version,num_workers,time_secs" > $output_file_stealback
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file"  >> $output_file_stealback
        done
    done

fi

if [ "$1" = "hashing" ]; then

    echo "version,num_workers,time_secs" > $output_file_hashing
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector hashing" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file"  >> $output_file_hashing
        done
    done

fi

if [ "$1" = "stealback_mugging" ]; then

    echo "version,num_workers,time_secs" > $output_file_stealbackmugging
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector mugging" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file"  >> $output_file_stealbackmugging
        done
    done

fi

if [ "$1" = "mugging" ]; then

    echo "version,num_workers,time_secs" > $output_file_mugging
    VERSION="mugging"

    cargo build --release --no-default-features --features "safe  mugging" -p bh
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $input_file $output $N 2>> "$dump_file"  >> $output_file_mugging
        done
    done

fi