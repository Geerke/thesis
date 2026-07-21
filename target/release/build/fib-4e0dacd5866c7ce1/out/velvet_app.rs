pub(crate) enum __Frame__ {
    Stolen(std::sync::Arc<std::sync::Mutex<Option<__Frame__>>>),
    InputFib(usize, u64),
    OutputFib(u64),
}
impl velvet::Identifiable for __Frame__ {
    fn get_id(&self) -> usize {
        if let __Frame__::InputFib(uid, ..) = self {
            return *uid;
        }
        return 0;
    }
}
fn __velvet_steal__(worker: &mut velvet::VelvetWorker<__Frame__>) {
    #[cfg(feature = "stats")]
    let __steal_start = std::time::Instant::now();
    let _id = worker.get_id();
    let len = worker.stealers.len();
    let mut stealback = false;
    #[cfg(feature = "hashing")]
    let mut target: Option<usize> = None;
    #[cfg(feature = "hashing")]
    let mut target_computed = false;
    #[cfg(feature = "hashing")]
    let mut candidates: Vec<usize> = Vec::new();
    #[cfg(feature = "hashing")]
    let mut ensure_target = |worker: &velvet::VelvetWorker<__Frame__>| -> Option<usize> {
        if !target_computed {
            target_computed = true;
            let mut owners = Vec::new();
            for owner in 0..len {
                if let Some(worker_id) = worker.stealers[owner].get_owner() {
                    if worker_id == owner {
                        owners.push(owner);
                    }
                }
            }
            if !owners.is_empty() {
                target = Some(owners[worker.get_random_withself(owners.len())]);
            }
        }
        target
    };
    #[cfg(feature = "hashing")]
    let mut pick_hashed = |
        worker: &velvet::VelvetWorker<__Frame__>,
        victim: usize,
        candidates: &mut Vec<usize>,
    | -> usize {
        candidates.clear();
        candidates.push(victim);
        worker.stealers[victim].extend_with_workers(candidates, _id);
        candidates[worker.get_random_withself(candidates.len())]
    };
    let has_owner = worker.stealers[_id].get_owner().is_some();
    let mut n = match worker.steal_back() {
        Some(i) => {
            stealback = true;
            i
        }
        None => {
            if has_owner {
                #[cfg(feature = "hashing")]
                {
                    match ensure_target(worker) {
                        Some(victim) => pick_hashed(worker, victim, &mut candidates),
                        None => worker.get_random(len),
                    }
                }
                #[cfg(not(feature = "hashing"))] worker.get_random(len)
            } else {
                0
            }
        }
    };
    for _ in 0..len {
        let stealer = worker.stealers[n].clone();
        #[cfg(feature = "mugging")]
        {
            if stealback {
                let mut amount_task = stealer.length();
                for task in 0..amount_task {
                    let result_slot_mugging = std::sync::Arc::new(
                        std::sync::Mutex::new(None),
                    );
                    let mut lock = result_slot_mugging.lock().unwrap();
                    let maybe_frame = stealer
                        .steal(__Frame__::Stolen(result_slot_mugging.clone()));
                    #[cfg(feature = "stats")] worker.add_steal_attempts(1);
                    if let Some(frame) = maybe_frame {
                        #[cfg(feature = "stats")]
                        worker.add_steal_waittime(__steal_start.elapsed());
                        match frame {
                            __Frame__::InputFib(_, a0) => {
                                let result = crate::fib(worker, a0);
                                *lock = Some(__Frame__::OutputFib(result));
                            }
                            _ => panic!("WRONG STOLEN WORK FRAME!"),
                        }
                        #[cfg(feature = "stats")] worker.add_successful_steals(1);
                    }
                    amount_task = stealer.length();
                }
                continue;
            }
        }
        let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
        let mut lock = result_slot.lock().unwrap();
        let maybe_frame = worker
            .stealers[n]
            .steal(__Frame__::Stolen(result_slot.clone()));
        #[cfg(feature = "stats")] worker.add_steal_attempts(1);
        if let Some(frame) = maybe_frame {
            #[cfg(feature = "stats")] worker.add_steal_waittime(__steal_start.elapsed());
            if !stealback {
                match worker.stealers[n].get_owner() {
                    Some(i) => {
                        worker.stealers[i].successfullsteal(_id);
                        worker.stealers[_id].set_owner(i);
                    }
                    None => {
                        worker.stealers[n].successfullsteal(_id);
                        if n != 0 {
                            worker.stealers[_id].set_owner(n);
                        } else {
                            worker.stealers[_id].set_owner(_id);
                        }
                    }
                }
            }
            match frame {
                __Frame__::InputFib(_, a0) => {
                    let result = crate::fib(worker, a0);
                    *lock = Some(__Frame__::OutputFib(result));
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
                        match ensure_target(worker) {
                            Some(victim) => pick_hashed(worker, victim, &mut candidates),
                            None => worker.get_random(len),
                        }
                    }
                    #[cfg(not(feature = "hashing"))] worker.get_random(len)
                }
            };
        } else if !has_owner {
            n = 0;
        } else {
            #[cfg(not(feature = "hashing"))]
            {
                n = (n + 1) % len;
            }
            #[cfg(feature = "hashing")]
            {
                n = match ensure_target(worker) {
                    Some(victim) => pick_hashed(worker, victim, &mut candidates),
                    None => worker.get_random(len),
                };
            }
        }
    }
    #[cfg(feature = "stats")] worker.add_steal_waittime(__steal_start.elapsed());
}
