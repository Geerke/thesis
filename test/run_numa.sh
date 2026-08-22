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



if [ "$1" = "topo" ]; then
    output_fib="AA_SLURM_OUT/NUMA/outtopopriorityfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/NUMA/outtopopriorityada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/NUMA/outtopoprioritytsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/NUMA/outtopoprioritymatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/NUMA/outtopoprioritynqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/NUMA/outtopoprioritybh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe  topology priority" -p fib
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe  topology priority" -p adapint
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe  topology priority" -p tsp
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42


    cargo build --release --no-default-features --features "safe  topology priority" -p matmul
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16 


    cargo build --release --no-default-features --features "safe  topology priority" -p nqueens
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram\
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15



    cargo build --release --no-default-features --features "safe  topology priority" -p bh
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5

fi

if [ "$1" = "random" ]; then
    output_fib="AA_SLURM_OUT/NUMA/outrandomfib.$SLURM_JOB_ID"
    output_ada="AA_SLURM_OUT/NUMA/outrandomada.$SLURM_JOB_ID"
    output_tsp="AA_SLURM_OUT/NUMA/outrandomtsp.$SLURM_JOB_ID"
    output_matmul="AA_SLURM_OUT/NUMA/outrandommatmul.$SLURM_JOB_ID"
    output_nqueens="AA_SLURM_OUT/NUMA/outrandomnqueens.$SLURM_JOB_ID"
    output_bh="AA_SLURM_OUT/NUMA/outrandombh.$SLURM_JOB_ID"

    cargo build --release --no-default-features --features "safe" -p fib
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_fib \
    $executabe_file_fib velvet 50

    
    cargo build --release --no-default-features --features "safe" -p adapint
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_ada \
    $executabe_file_ada velvet 0.0 800000 0.0001

    cargo build --release --no-default-features --features "safe" -p tsp
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_tsp \
    $executabe_file_tsp velvet 19 42


    cargo build --release --no-default-features --features "safe" -p matmul
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_matmul \
    $executabe_file_matmul velvet 8 16 


    cargo build --release --no-default-features --features "safe " -p nqueens
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram\
    -o $output_nqueens \
    $executabe_file_nqueens velvet 15

    cargo build --release --no-default-features --features "safe " -p bh
    perf stat --repeat 5 -e ls_refills_from_sys.ls_mabresp_lcl_dram,ls_refills_from_sys.ls_mabresp_rmt_dram \
    -o $output_bh \
    $executabe_file_bh velvet "/var/scratch/abliokou/bh_data/two_plummers_1M.txt" "AA_SLURM_OUT/BH/output.$SLURM_JOB_ID" 5

fi