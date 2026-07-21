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
    let steal_start = std::time::Instant::now();
    let _id = worker.get_id();
    let stealers = &worker.stealers;
    let len = stealers.len();
    let mut n = worker.get_random(len);
    let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
    #[cfg(feature = "priority")]
    {
        let mut victim: Option<usize> = None;
        let mut size = 0;
        for _i in 0..len {
            let length = stealers[n].length();
            if length > size {
                victim = Some(n);
                size = length;
            }
            n = (n + 1) % len;
        }
        if let Some(v) = victim {
            let maybe_frame = stealers[v].steal(__Frame__::Stolen(result_slot.clone()));
            #[cfg(feature = "stats")] worker.add_steal_attempts(1);
            if let Some(frame) = maybe_frame {
                #[cfg(feature = "stats")]
                worker.add_steal_waittime(steal_start.elapsed());
                match frame {
                    __Frame__::InputFib(_, a0) => {
                        let result = crate::fib(worker, a0);
                        {
                            let mut lock = result_slot.lock().unwrap();
                            *lock = Some(__Frame__::OutputFib(result));
                        };
                    }
                    _ => panic!("WRONG STOLEN WORK FRAME!"),
                }
                #[cfg(feature = "stats")] worker.add_successful_steals(1);
                return;
            }
        }
        n = worker.get_random(len);
    }
    for _ in 0..len {
        let maybe_frame = worker
            .stealers[n]
            .steal(__Frame__::Stolen(result_slot.clone()));
        #[cfg(feature = "stats")] worker.add_steal_attempts(1);
        if let Some(frame) = maybe_frame {
            #[cfg(feature = "stats")] worker.add_steal_waittime(steal_start.elapsed());
            match frame {
                __Frame__::InputFib(_, a0) => {
                    let result = crate::fib(worker, a0);
                    {
                        let mut lock = result_slot.lock().unwrap();
                        *lock = Some(__Frame__::OutputFib(result));
                    };
                }
                _ => panic!("WRONG STOLEN WORK FRAME!"),
            }
            #[cfg(feature = "stats")]
            {
                worker.add_successful_steals(1);
            }
            return;
        }
        n = (n + 1) % len;
    }
    #[cfg(feature = "stats")] worker.add_steal_waittime(steal_start.elapsed());
}
