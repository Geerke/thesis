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
    for _ in 0..len {
        let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
        let mut lock = result_slot.lock().unwrap();
        if let Some(target) = worker.get_victim() {
            let maybe_frame = worker
                .stealers[target]
                .steal(__Frame__::Stolen(result_slot.clone()));
            #[cfg(feature = "stats")] worker.add_steal_attempts(1);
            if let Some(frame) = maybe_frame {
                #[cfg(feature = "stats")]
                worker.add_steal_waittime(steal_start.elapsed());
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
                }
                return;
            }
        } else {
            return
        }
    }
    #[cfg(feature = "stats")] worker.add_steal_waittime(steal_start.elapsed());
}
