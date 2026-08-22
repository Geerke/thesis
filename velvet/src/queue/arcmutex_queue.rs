#[cfg(any(feature = "register", feature = "hashing_register"))]
#[cfg(any(feature = "stats"))]
use std::{time::Duration};

use std::{collections::{HashMap, VecDeque, HashSet}, sync::{Arc, Mutex, atomic::{AtomicUsize, AtomicU64, Ordering, AtomicBool}}};

use super::Identifiable;


#[cfg(feature = "register")]
const HIGH: usize= 6;
#[cfg(feature = "register")]
const LOW: usize= 3;

pub(crate) struct Queue<T: Identifiable> {
	queue: Arc<Mutex<VecDeque<T>>>,
	stolen: Arc<Mutex<HashMap<usize, T>>>,
    
    #[cfg(feature = "stealbackhash")]
    stealers: Arc<Mutex<HashSet<usize>>>,
    #[cfg(feature = "stealbackvector")]
    stealers: Arc<Mutex<VecDeque<usize>>>,


    #[cfg(any(feature = "register", feature = "hashing_register"))]
    victims: Arc<VictimRegistry>,
    #[cfg(any(feature = "register"))]
    len: AtomicUsize,
    #[cfg(feature = "register")]
    registered: AtomicBool,
    #[cfg(any(feature = "register"))]
    worker_id: usize,
}  

impl <T: Identifiable> Queue<T> {
    pub(crate) fn new(capacity: usize , 
            #[cfg(any(feature = "register", feature = "hashing_register"))]
            victims: Arc<VictimRegistry>,
            #[cfg(any(feature = "register"))]
            _id:usize ) -> Self {
        Self {
            queue: Arc::new(Mutex::new(VecDeque::with_capacity(capacity))),
            stolen: Arc::new(Mutex::new(HashMap::new())),
            
            #[cfg(feature = "stealbackhash")]
            stealers: Arc::new(Mutex::new(HashSet::new())),

             #[cfg(feature = "stealbackvector")]
            stealers: Arc::new(Mutex::new(VecDeque::new())),
            #[cfg(any(feature = "register", feature = "hashing_register"))]
            victims,
            #[cfg(any(feature = "register"))]
            len: AtomicUsize::new(0),
            #[cfg(feature = "register")]
            registered: AtomicBool::new(false),
            #[cfg(any(feature = "register"))]
            worker_id: _id
        }
    }


   #[cfg(not(feature = "register"))]
    pub(crate) fn push(&self, frame: T) {
        self.queue.lock().unwrap().push_back(frame);
    }

   #[cfg(feature = "register")]
     pub(crate) fn push(&self, frame: T) {
        let old = {
            let mut q = self.queue.lock().unwrap();
            q.push_back(frame);
            self.len.fetch_add(1, Ordering::AcqRel)
        }; //add frame to workqueue, while holding the queue's lock get and change old size of register 
         if old >= HIGH-1{
            //only register if queue is not registered
            if self.registered
                .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
                .is_ok(){
                self.victims.register(self.worker_id);
            }
        }
    }


     #[cfg(not(feature = "register"))]
    pub(crate) fn pop(&self, uid: usize) -> T {
        match self.queue.lock().unwrap().pop_back() {
            Some(frame) => return frame,
            None => {
                loop {
                    if let Some(returnslot) = self.get_returnslot(uid) {
                        return returnslot;
                    }
                }
            }
        }
    
    }

    #[cfg(feature = "register")]
     pub(crate) fn pop(&self, uid: usize) -> T {
        let frame = self.queue.lock().unwrap().pop_back();
       
        
        match frame{
            Some(frame) => {
                let old = {
                    let _q = self.queue.lock().unwrap(); 
                    self.len.fetch_sub(1, Ordering::AcqRel)
                }; //Get old size of register
                if old <= LOW {
                    //only unregister if queue is registered
                    if self.registered
                        .compare_exchange(true, false, Ordering::AcqRel, Ordering::Acquire)
                        .is_ok()
                    {
                        self.victims.unregister(self.worker_id);

                    }
                }
                return frame
            },
            None => {
                loop {
                    if let Some(returnslot) = self.get_returnslot(uid) {
                        let old = {
                            let _q = self.queue.lock().unwrap(); 
                            self.len.fetch_sub(1, Ordering::AcqRel)
                        }; //Get old size of register
                        if old <= LOW {
                            //only unregister if queue is registered
                            if self.registered
                                .compare_exchange(true, false, Ordering::AcqRel, Ordering::Acquire)
                                .is_ok()
                            {
                                self.victims.unregister(self.worker_id);
                            }
                        }
                        return returnslot;
                    }
                }
            }
        }
    
    }

     #[cfg(not(feature = "register"))]
	pub(crate) fn steal(&self, trace: T) -> Option<T> {
        let stolen = self.queue.lock().unwrap().pop_front();
        
		if let Some(ref job) = stolen {
			let id = job.get_id();
			self.stolen.lock().expect("failed to lock when stealing").insert(id, trace);
		}

        stolen
	}

     #[cfg(feature = "register")]
     pub(crate) fn steal(&self, trace: T) -> Option<T> {
        let stolen = self.queue.lock().unwrap().pop_front();
       
		if let Some(ref job) = stolen {
			let id = job.get_id();
			self.stolen.lock().expect("failed to lock when stealing").insert(id, trace);
            let old = {
                let _q = self.queue.lock().unwrap(); 
                self.len.fetch_sub(1, Ordering::AcqRel)
            }; //Get old size of register
             if old <= LOW {
                //only unregister if queue is registered
                if self.registered
                    .compare_exchange(true, false, Ordering::AcqRel, Ordering::Acquire)
                    .is_ok()
                {
                    self.victims.unregister(self.worker_id);
                }
            }
		}

        stolen
	}

    #[cfg(any(feature = "topology", feature = "priority", feature = "mugging"))]
    pub(crate) fn len(&self) -> usize{
        self.queue.lock().expect("failed to lock when stealing").len()
    }

    #[cfg(any(feature = "stealbackhash"))]
    pub(crate) fn add_stealer(&self, id: usize){
        self.stealers.lock().expect("failed to lock when stealing").insert(id);
    }

    #[cfg(feature = "stealbackvector")]
    pub(crate) fn add_stealer(&self, id: usize){
        //first check if id already in list, if so remove that value
        let mut stealers = self.stealers.lock().expect("failed to lock when stealing");
        if let Some(index) = stealers.iter().position(|&x| x == id) {
                stealers.remove(index);
        }
        stealers.push_back(id);
    }
    #[cfg(feature = "stealbackhash")]
    pub(crate) fn remove_stealer(&self, id:usize){
        self.stealers.lock().expect("failed to lock when stealing").remove(&id);   
    }

    #[cfg(feature = "stealbackvector")]
    pub(crate) fn remove_stealer(&self, id:usize){  
        let mut stealers = self.stealers.lock().expect("failed to lock when stealing");

        if let Some(index) = stealers.iter().position(|&x| x == id) {
            stealers.remove(index);
        }
    }
    
   
    #[cfg(feature = "stealbackhash")]
    pub(crate) fn get_stolen(&self) -> Option<usize>{
        self.stealers.lock().expect("failed to lock when stealing").iter().next().copied()
    }//Return potential victim from stealers queue
    
    #[cfg(feature = "stealbackhash")]
    pub(crate) fn get_stealers_length(&self) -> usize{
        self.stealers.lock().expect("failed to lock when stealing").len()
    }
     
    
     #[cfg(feature = "stealbackvector")]
    pub(crate) fn get_stolen(&self) -> Option<usize>{
        self.stealers.lock().expect("failed to lock when stealing").pop_back()
    } //Return potential victim from stealers queue
     
    #[cfg(any(feature = "register", feature = "hashing_register"))]
     pub fn get_victim(&self, self_id: usize) -> Option<usize>{
        let victims = self.victims.victims.lock().unwrap();
        victims.iter().rev().find(|&&id| id != self_id).copied()
    }

	fn get_returnslot(&self, uid: usize) -> Option<T> {
		return self.stolen.lock().expect("failed to lock when receiving").remove(&uid);
	}
}

pub struct Stealer<T:Identifiable>  { 
    queue: Arc<Queue<T>>, 
    task_owner: Option<usize>, 
    #[cfg(feature = "hashing_register")]
    victims: Arc<VictimRegistry>
}
impl <T: Identifiable> Stealer<T>  {
    pub(crate) fn new(queue: Arc<Queue<T>>, #[cfg(feature = "hashing_register")] victims: Arc<VictimRegistry>  ) -> Self {
        Self {queue, task_owner: None, #[cfg(feature = "hashing_register")] victims}
    }
    // interface to steal
    pub fn steal(&self, trace: T) -> Option<T> {
        self.queue.steal(trace)
    }

    #[cfg(any(feature = "stealbackhash", feature = "stealbackvector"))]
    pub fn set_owner(&mut self, owner: usize, id:usize){
        #[cfg(feature = "hashing_register")]
        {
            if owner == id{
                self.victims.register(id);
            }
            else if let Some(old) = self.task_owner{
                if old == id{
                    self.victims.unregister(id);
                }
            }
        }
        
        
        self.task_owner = Some(owner);
    }

    #[cfg(any(feature = "stealbackhash", feature = "stealbackvector"))]
    pub fn get_owner(&self) -> Option<usize>{
        self.task_owner
    }
    
    
    #[cfg(feature = "topology")]
    pub fn ready(&self) -> bool{
        if self.queue.len() < 1{
            return false
        }
        true
    } //Return true if enough victims left in queue, otherwise false
    
    #[cfg(any(feature = "topology", feature = "priority", feature = "mugging"))]
    pub fn length(&self) -> usize{
        self.queue.len()
    }

   
    #[cfg(any(feature = "stealbackhash", feature = "stealbackvector"))]
    pub fn successfullsteal(&self, id:usize){
        self.queue.add_stealer(id);
    }  //add the ID of a stealer that successfully stole from queue
    
   
    #[cfg(any(feature = "stealbackhash", feature = "stealbackvector"))]
   pub fn extend_with_workers(&self, candidates: &mut Vec<usize>, id: usize) {
        let guard = self.queue.stealers.lock().expect("failed to lock when stealing");
        candidates.extend(guard.iter().copied().filter(|&x| x != id));
    }  //Returns given vector with all workers id that are in stealers
}
impl <T: Identifiable> Clone for Stealer<T> {
    fn clone(&self) -> Self {
        Self { queue: self.queue.clone(), task_owner: self.task_owner.clone(), #[cfg(feature = "hashing_register")] victims: self.victims.clone()}
    }
}

#[cfg(any(feature = "register", feature = "hashing_register"))]
pub struct VictimRegistry {
    victims: Mutex<VecDeque<usize>>,

    #[cfg(any(feature = "stats"))]
    time: AtomicU64

}
#[cfg(any(feature = "register", feature = "hashing_register"))]
impl VictimRegistry {
    pub fn new() -> Self {

        Self {
            victims: Mutex::new(VecDeque::new()),
                
            #[cfg(any(feature = "stats"))]
            time: AtomicU64::new(0),
        }
    }
    pub fn register(&self, id: usize) {
        #[cfg(any(feature = "stats"))]
        let start = std::time::Instant::now();
        
        let mut victims = self.victims.lock().unwrap();
        if !victims.iter().any(|&i| i == id) {
            victims.push_back(id);

        }
        #[cfg(any(feature = "stats"))]
        {
            drop(victims);
            self.time.fetch_add(start.elapsed().as_nanos() as u64, Ordering::Relaxed);
        }


    }
    pub fn unregister(&self, id: usize){
         #[cfg(any(feature = "stats"))]
        let start = std::time::Instant::now();
        
        let mut victims = self.victims.lock().unwrap();
        victims.retain(|&i| i != id);

        #[cfg(any(feature = "stats"))]
        {
             drop(victims);
            self.time.fetch_add(start.elapsed().as_nanos() as u64, Ordering::Relaxed);
        }
    }
    
    #[cfg(any(feature = "stats"))]
    pub fn total_busy_time(&self) -> std::time::Duration {
        std::time::Duration::from_nanos(self.time.load(Ordering::Relaxed))
    }
}

/*
#[cfg(test)]
mod test_arcmutex {
    use super::*;
    use crate::queue::VelvetStealer;

    #[derive(Debug, PartialEq)]
    struct Frame {
        content: usize,
        id: usize,
    }
    impl Identifiable for Frame {
        fn get_id(&self) -> usize {
            self.id
        }
    }

    // test the queue: push & pop
    #[test]
    fn queue_pp() {
        let q: Queue<Frame, Frame> = Queue::new(4);

        q.push(Frame { content: 0, id: 0 });
        q.push(Frame { content: 1, id: 1 });
        q.push(Frame { content: 2, id: 2 });
        
        assert_eq!(q.pop(2), Frame { content: 2, id: 2 });
        assert_eq!(q.pop(1), Frame { content: 1, id: 1 });

        q.push(Frame { content: 3, id: 3 });
        assert_eq!(q.pop(3), Frame { content: 3, id: 3 });
        assert_eq!(q.pop(0), Frame { content: 0, id: 0 });
        
        q.push(Frame { content: 0, id: 0 });
        q.push(Frame { content: 1, id: 1 });
        q.push(Frame { content: 2, id: 2 });
        q.push(Frame { content: 3, id: 3 });
        q.push(Frame { content: 4, id: 4 }); // check buffer is grown (no panic)
    }

    // test the queue: steal
    #[test]
    fn queue_steal() {
        let q = Arc::new(Queue::<Frame, Frame>::new(4));
        let s = VelvetStealer { queue: q.clone() };

        assert_eq!(s.steal(Frame { content: 0, id: 0 }), None);

        q.push(Frame { content: 1, id: 1 });
        q.push(Frame { content: 2, id: 2 });
        q.push(Frame { content: 3, id: 3 });
        
        assert_eq!(s.steal(Frame { content: 0, id: 0 }), Some(Frame { content: 1, id: 1 }));
        assert_eq!(s.steal(Frame { content: 4, id: 4 }), Some(Frame { content: 2, id: 2 }));
        assert_eq!(q.pop(3), Frame { content: 3, id: 3 });
        assert_eq!(q.pop(1), Frame { content: 0, id: 0 });
        assert_eq!(q.pop(2), Frame { content: 4, id: 4 });
    }

    // test the queue: multithreaded
    // #[test]
    // fn queue_multithreaded() {
    //     use std::{sync::{atomic::{AtomicBool, Ordering}, Barrier}, thread};
    //     let problem_size = 4096;
    //     let num_threads = 12;
    //     // queue
    //     let q: Arc<Queue<usize>> = Arc::new(Queue::new(problem_size));
    //     // barrier
    //     let barrier = Arc::new(Barrier::new(num_threads));
    //     // signal
    //     let signal = Arc::new(AtomicBool::new(true));
    //     // spawn worker threads (thieves)
    //     let mut handles = Vec::new();
    //     for _thread_id in 0..num_threads-1 {
    //         let barrier = barrier.clone();
    //         let stealer = Stealer { queue: q.clone() };
    //         let signal = signal.clone();
    //         handles.push(thread::spawn(move || {
    //             barrier.wait();
    //             // steal work
    //             while signal.load(Ordering::Relaxed) {
    //                 if let Some((id, task)) = stealer.steal() {
    //                     // println!("thread id {} got task at queue index {}", _thread_id, id);
    //                     stealer.return_stolen(id, task*10);
    //                 }
    //             }
    //         }));
    //     }

    //     // root worker
    //     barrier.wait();
    //     for i in 0..problem_size {
    //         q.push(i);
    //     }

    //     for expected in (0..problem_size).rev() {
    //         match q.pop() {
    //             Pop::Empty => panic!("queue should not be empty at idx {}", expected),
    //             Pop::Job(i) => {
    //                 // println!("worker popped a local job at index {}", i);
    //                 assert_eq!(i, expected)
    //             },
    //             Pop::StolenDone(i) => assert_eq!(i, expected*10),
    //             Pop::StolenInProgress => {
    //                 loop {
    //                     match q.pop() {
    //                         Pop::StolenDone(i) => { 
    //                             assert_eq!(i, expected*10);
    //                             break;
    //                         },
    //                         _ => (),
    //                     }
    //                 }
    //             }
    //         }
    //     }
       
    //    // shutdown
    //     signal.store(false, Ordering::Relaxed);
    //     for handle in handles {
    //         let _ = handle.join();
    //     }
    // }
}*/