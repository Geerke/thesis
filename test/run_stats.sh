#!/bin/bash
#SBATCH --time=15:00
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --hint=compute_bound

. /etc/bashrc

export RUSTFLAGS="-L/opt/ohpc/pub/libs/hwloc/lib -C link-arg=-Wl,-rpath,/opt/ohpc/pub/libs/hwloc/lib"


dump_file="AA_SLURM_OUT/STATS/err."

echo "Saving logs to $output_file"


executabe_file_tsp="./target/release/tsp"
executabe_file_fib="./target/release/fib"
executabe_file_matmul="./target/release/matmul"
executabe_file_nqueens="./target/release/nqueens"
executabe_file_ada="./target/release/adapint"
executabe_file_bh="./target/release/bh"


workers=32
export VELVET_WORKERS=$workers  


if [ "$1" = "random" ]; then 
    VERSION="random"
    export VELVET_WORKERS=$workers  
    output_fib="AA_SLURM_OUT/STATS/outrandomfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outrandomada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outrandomtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outrandommatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outrandomnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outrandombh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats" -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi


if [ "$1" = "topo" ]; then
    output_fib="AA_SLURM_OUT/STATS/outtopofib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outtopoada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outtopotsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outtopomatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outtoponqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outtopobh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats topology" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology" -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi

if [ "$1" = "topopriority" ]; then
    output_fib="AA_SLURM_OUT/STATS/outtopopriorityfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outtopopriorityada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outtopoprioritytsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outtopoprioritymatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outtopoprioritynqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outtopoprioritybh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats topology priority" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology priority" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology priority" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology priority" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology priority" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats topology priority" -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi

if [ "$1" = "priority" ]; then
    output_fib="AA_SLURM_OUT/STATS/outpriorityfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outpriorityada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outprioritytsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outprioritymatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outprioritynqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outprioritybh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats  priority" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats  priority" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats  priority" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats  priority" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats  priority" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats priority" -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi

if [ "$1" = "register" ]; then
    output_fib="AA_SLURM_OUT/STATS/outregisterfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outregisterada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outregistertsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outregistermatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outregisternqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outregisterbh.$SLURM_JOB_ID"

    # cargo build --release --no-default-features --features "safe stats  register" -p fib
    # for iter in {1..5}; do
    #     $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    # done

    # cargo build --release --no-default-features --features "safe stats  register" -p adapint
    # for iter in {1..5}; do
    #     $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    # done

    # cargo build --release --no-default-features --features "safe stats  register" -p tsp
    # for iter in {1..5}; do
    #     $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    # done

    cargo build --release --no-default-features --features "safe stats  register" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    # cargo build --release --no-default-features --features "safe stats  register" -p nqueens
    # for iter in {1..5}; do
    #     $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    # done

    # cargo build --release --no-default-features --features "safe stats register" -p bh
    # for iter in {1..5}; do
    #     $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    # done
fi



if [ "$1" = "stealback" ]; then
    output_fib="AA_SLURM_OUT/STATS/outstealbackfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outstealbackada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outstealbacktsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outstealbackmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outstealbacknqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outstealbackbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats stealbackvector" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector " -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector " -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector " -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector " -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector " -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi

if [ "$1" = "hashing" ]; then
    output_fib="AA_SLURM_OUT/STATS/outhashingfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outhashingada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outhashingtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outhashingmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outhashingnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outhashingbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing" -p fib
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector hashing " -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done
fi


if [ "$1" = "mugging" ]; then
    echo "thread_id,total_steal_attempts,successful_steals,attempts_before_first_success,succesful_steal_backs,work_time,steal_setup_time,steal_waiting,pop_waiting,pop_waiting_other,push_waiting,push_waiting_other,other_time,spawns,spawns_other,total_stolen_jobs,total_stolen_jobs_other,sync_loop_iters,sync_loop_iters_other" > $output_file_mugging

    
    output_fib="AA_SLURM_OUT/STATS/outmuggingfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/STATS/outmuggingada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/STATS/outmuggingtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/STATS/outmuggingmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/STATS/outmuggingnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/STATS/outmuggingbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe stats stealbackvector mugging" -p fib
    
    for iter in {1..5}; do
        $executabe_file_fib velvet 50 2>> "$output_fib" >> $dump_file
    done
    
    cargo build --release --no-default-features --features "safe stats stealbackvector mugging" -p adapint
    for iter in {1..5}; do
        $executabe_file_ada velvet 0.0 800000 0.0001 2>> "$output_ada" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector mugging" -p tsp
    for iter in {1..5}; do
        $executabe_file_tsp velvet 19 42 2>> "$output_tsp" >> $dump_file
    done


    cargo build --release --no-default-features --features "safe stats stealbackvector mugging" -p matmul
    for iter in {1..5}; do
        $executabe_file_matmul velvet 9 8 2>> "$output_matmul" >> $dump_file
    done


    cargo build --release --no-default-features --features "safe stats stealbackvector mugging" -p nqueens
    for iter in {1..5}; do
        $executabe_file_nqueens velvet 15 2>> "$output_nqueens" >> $dump_file
    done

    cargo build --release --no-default-features --features "safe stats stealbackvector mugging " -p bh
    for iter in {1..5}; do
        $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5 2>> "$output_bh" >> $dump_file
    done

fi