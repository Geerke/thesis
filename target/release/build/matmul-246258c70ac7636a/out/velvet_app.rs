pub(crate) enum __Frame__ {
    Stolen(std::sync::Arc<std::sync::Mutex<Option<__Frame__>>>),
    InputSpawnMatmul(
        usize,
        std::sync::Arc<crate::matrix_par::Matrix>,
        usize,
        std::sync::Arc<crate::matrix_par::Matrix>,
        std::sync::Arc<crate::matrix_par::Matrix>,
    ),
}
impl velvet::Identifiable for __Frame__ {
    fn get_id(&self) -> usize {
        if let __Frame__::InputSpawnMatmul(uid, ..) = self {
            return *uid;
        }
        return 0;
    }
}
fn __velvet_steal__(worker: &mut velvet::VelvetWorker<__Frame__>) {
    #[cfg(feature = "stats")]
    let __steal_start = std::time::Instant::now();
    let stealers = &worker.stealers;
    let _id = worker.get_id();
    let len = stealers.len();
    let mut stealback = false;
    let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
    let mut lock = result_slot.lock().unwrap();
    let target = worker.stealers[_id].get_victim(_id);
    let mut n = match worker.steal_back() {
        Some(i) => {
            stealback = true;
            i
        }
        None => {
            if worker.stealers[_id].get_owner().is_some() {
                #[cfg(feature = "hashing")]
                {
                    if let Some(victim) = target {
                        let mut candidates = vec![victim];
                        worker
                            .stealers[victim]
                            .extend_with_workers(&mut candidates, _id);
                        candidates[worker.get_random_withself(candidates.len())]
                    } else {
                        worker.get_random(len)
                    }
                }
                #[cfg(not(feature = "hashing"))] worker.get_random(len)
            } else {
                0
            }
        }
    };
    for _ in 0..len {
        let maybe_frame = worker
            .stealers[n]
            .steal(__Frame__::Stolen(result_slot.clone()));
        #[cfg(feature = "stats")] worker.add_steal_attempts(1);
        if let Some(frame) = maybe_frame {
            #[cfg(feature = "stats")] worker.add_steal_waittime(__steal_start.elapsed());
            if !(stealback) {
                match worker.stealers[n].get_owner() {
                    Some(i) => {
                        worker.stealers[i].successfullsteal(_id);
                        worker.stealers[_id].set_owner(i, _id);
                    }
                    None => {
                        worker.stealers[n].successfullsteal(_id);
                        if n != 0 {
                            worker.stealers[_id].set_owner(n, _id);
                        } else {
                            worker.stealers[_id].set_owner(_id, _id);
                        }
                    }
                }
            }
            match frame {
                __Frame__::InputSpawnMatmul(_, a0, a1, a2, a3) => {
                    a0.spawn_matmul(worker, a1, a2, a3);
                    *lock = None;
                }
                _ => panic!("WRONG STOLEN WORK FRAME!"),
            }
            #[cfg(feature = "stats")]
            {
                worker.add_successful_steals(1);
                if stealback {
                    worker.add_successful_stealback(1);
                }
            }
            return;
        }
        if stealback {
            worker.unsuccessfullsteal(n);
            n = match worker.steal_back() {
                Some(i) => {
                    stealback = true;
                    i
                }
                None => {
                    stealback = false;
                    #[cfg(feature = "hashing")]
                    {
                        if let Some(victim) = target {
                            let mut candidates = vec![victim];
                            worker
                                .stealers[victim]
                                .extend_with_workers(&mut candidates, _id);
                            candidates[worker.get_random_withself(candidates.len())]
                        } else {
                            worker.get_random(len)
                        }
                    }
                    #[cfg(not(feature = "hashing"))] worker.get_random(len)
                }
            };
        } else {
            if !worker.stealers[_id].get_owner().is_some() {
                n = 0
            } else {
                n = (n + 1) % len;
                #[cfg(feature = "hashing")]
                {
                    if let Some(victim) = target {
                        let mut candidates = vec![victim];
                        worker
                            .stealers[victim]
                            .extend_with_workers(&mut candidates, _id);
                        n = candidates[worker.get_random_withself(candidates.len())];
                    } else {
                        n = worker.get_random(len);
                    }
                }
            }
        }
    }
    #[cfg(feature = "stats")] worker.add_steal_waittime(__steal_start.elapsed());
}
