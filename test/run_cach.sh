#!/bin/bash
#SBATCH --time=15:00
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --hint=compute_bound

. /etc/bashrc

export RUSTFLAGS="-L/opt/ohpc/pub/libs/hwloc/lib -C link-arg=-Wl,-rpath,/opt/ohpc/pub/libs/hwloc/lib"
export VELVET_WORKERS=32



executabe_file_tsp="./target/release/tsp"
executabe_file_fib="./target/release/fib"
executabe_file_matmul="./target/release/matmul"
executabe_file_nqueens="./target/release/nqueens"
executabe_file_ada="./target/release/adapint"
executabe_file_bh="./target/release/bh"

if [ "$1" = "random" ]; then 
    VERSION="random"
    output_fib="AA_SLURM_OUT/CACHE/outrandomfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outrandomada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outrandomtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outrandommatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outrandomnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outrandombh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe " -p fib
    
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe " -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe " -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp\
    $executabe_file_tsp velvet 19 42
    
    cargo build --release --no-default-features --features "safe " -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16


    cargo build --release --no-default-features --features "safe " -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe " -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5
fi


if [ "$1" = "topo" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outtopofib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outtopoada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outtopotsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outtopomatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outtoponqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outtopobh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  topology" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe  topology" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe  topology" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42


    cargo build --release --no-default-features --features "safe  topology" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16 


    cargo build --release --no-default-features --features "safe  topology" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe  topology" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,node-loads,node-load-misses,node-stores,node-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5

fi

if [ "$1" = "topopriority" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outtopopriorityfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outtopopriorityada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outtopoprioritytsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outtopoprioritymatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outtopoprioritynqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outtopoprioritybh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  topology priority" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe  topology priority" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe  topology priority" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42


    cargo build --release --no-default-features --features "safe  topology priority" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16 


    cargo build --release --no-default-features --features "safe  topology priority" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe  topology priority" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5

fi


if [ "$1" = "priority" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outpriorityfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outpriorityada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outprioritytsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outprioritymatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outprioritynqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outprioritybh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe   priority" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe   priority" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe   priority" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42


    cargo build --release --no-default-features --features "safe   priority" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16 


    cargo build --release --no-default-features --features "safe   priority" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe   priority" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5

fi


if [ "$1" = "stealback" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outstealbackfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outstealbackada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outstealbacktsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outstealbackmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outstealbacknqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outstealbackbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  stealbackvector " -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
     -o $output_fib \
    $executabe_file_fib velvet 50 

    
    cargo build --release --no-default-features --features "safe  stealbackvector " -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001 

    cargo build --release --no-default-features --features "safe  stealbackvector " -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42 


    cargo build --release --no-default-features --features "safe  stealbackvector " -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16


    cargo build --release --no-default-features --features "safe  stealbackvector " -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe stealbackvector " -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5
fi


if [ "$1" = "hashing" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outhashingfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outhashingada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outhashingtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outhashingmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outhashingnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outhashingbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  stealbackvector hashing" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
     -o $output_fib \
    $executabe_file_fib velvet 50 

    
    cargo build --release --no-default-features --features "safe  stealbackvector hashing" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001 

    cargo build --release --no-default-features --features "safe  stealbackvector hashing" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42 


    cargo build --release --no-default-features --features "safe  stealbackvector hashing" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16


    cargo build --release --no-default-features --features "safe  stealbackvector hashing" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe stealbackvector hashing" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5
fi


if [ "$1" = "mugging" ]; then
    output_fib="AA_SLURM_OUT/CACHE/outmuggingfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outmuggingada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outmuggingtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outmuggingmatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outmuggingnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outmuggingbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  mugging" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
     -o $output_fib \
    $executabe_file_fib velvet 50 

    
    cargo build --release --no-default-features --features "safe mugging" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001 

    cargo build --release --no-default-features --features "safe mugging" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42 


    cargo build --release --no-default-features --features "safe mugging" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16


    cargo build --release --no-default-features --features "safe mugging" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe mugging" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5
fi


if [ "$1" = "register" ]; then
   output_fib="AA_SLURM_OUT/CACHE/outregisterfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/CACHE/outregisterada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/CACHE/outregistertsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/CACHE/outregistermatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/CACHE/outregisternqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/CACHE/outregisterbh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe register" -p fib
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
     -o $output_fib \
    $executabe_file_fib velvet 50 

    
    cargo build --release --no-default-features --features "safe register" -p adapint
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001 

    cargo build --release --no-default-features --features "safe register" -p tsp
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42 


    cargo build --release --no-default-features --features "safe register" -p matmul
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16


    cargo build --release --no-default-features --features "safe register" -p nqueens
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe mugging" -p bh
    perf stat --repeat 5 -e cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5
fi 