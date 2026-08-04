#!/bin/bash
#SBATCH --time=15:00
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --hint=compute_bound

. /etc/bashrc

export RUSTFLAGS="-L/opt/ohpc/pub/libs/hwloc/lib -C link-arg=-Wl,-rpath,/opt/ohpc/pub/libs/hwloc/lib"

output_file_seq="AA_SLURM_OUT/TSP/outseq.$SLURM_JOB_ID"
output_file_ran="AA_SLURM_OUT/TSP/outrandom.$SLURM_JOB_ID"
output_file_topo="AA_SLURM_OUT/TSP/outtopo.$SLURM_JOB_ID"
output_file_stealback="AA_SLURM_OUT/TSP/outstealback.$SLURM_JOB_ID"
output_file_hashing="AA_SLURM_OUT/TSP/outhashing.$SLURM_JOB_ID"
output_file_priority="AA_SLURM_OUT/TSP/outpriority.$SLURM_JOB_ID"
output_file_registry="AA_SLURM_OUT/TSP/outregistry.$SLURM_JOB_ID"
output_file_stealbackmugging="AA_SLURM_OUT/TSP/outstealbackmugging.$SLURM_JOB_ID"
output_file_mugging="AA_SLURM_OUT/TSP/outmugging.$SLURM_JOB_ID"



dump_file="AA_SLURM_OUT/TSP/err.$SLURM_JOB_ID"




echo "Saving logs to $output_file_seq"


executabe_file="./target/release/tsp"

N=19

VERSION="seq"

if [ "$1" = "seq" ]; then
    echo "version,num_workers,time_secs" > $output_file_seq
    
    cargo build --release -p tsp
    for iter in {1..6}; do
        $executabe_file seq $N 42 2>> $dump_file | awk -v v="$VERSION" -v w="1" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_seq"
    done
fi 



if [ "$1" = "random" ]; then
    echo "version,num_workers,time_secs" > $output_file_ran
    
    VERSION="random"

    cargo build --release --no-default-features --features "safe" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_ran"
        done
    done

fi

if [ "$1" = "priority" ]; then
    echo "version,num_workers,time_secs" > $output_file_priority

    VERSION="priority"


    cargo build --release --no-default-features --features "safe priority" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_priority"
        done
    done

fi

if [ "$1" = "registry" ]; then
    echo "version,num_workers,time_secs" > $output_file_registry

    VERSION="registry"


    cargo build --release --no-default-features --features "safe register" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_registry"
        done
    done

fi


if [ "$1" = "topo" ]; then
    echo "version,num_workers,time_secs" > $output_file_topo

    VERSION="topology"


    cargo build --release --no-default-features --features "safe topology" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_topo"
        done
    done

fi

if [ "$1" = "stealback" ]; then
    echo "version,num_workers,time_secs" > $output_file_stealback
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_stealback"
        done
    done

fi

if [ "$1" = "hashing" ]; then
    echo "version,num_workers,time_secs" > $output_file_hashing
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector hashing" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_hashing"
        done
    done

fi

if [ "$1" = "stealback_mugging" ]; then
    echo "version,num_workers,time_secs" > $output_file_stealbackmugging
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe stealbackvector mugging" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_stealbackmugging"
        done
    done

fi

if [ "$1" = "mugging" ]; then
    echo "version,num_workers,time_secs" > $output_file_mugging
    VERSION="stealbackvector"

    cargo build --release --no-default-features --features "safe mugging" -p tsp
    for workers in 1 2 4 8 12 16 20 24 28 32
    do
        export VELVET_WORKERS=$workers

        for iter in {1..6}; do
            $executabe_file velvet $N 42  2>> "$dump_file" \
            | awk -v v="$VERSION" -v w="$workers" '
                /TIME:/ {
                    time=$NF
                    print v "," w "," time
                }
            ' >> "$output_file_mugging"
        done
    done

fi
