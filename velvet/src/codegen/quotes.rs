use quote::quote;
use proc_macro2::{TokenStream, Span};




use super::func_finding::FuncEntry;

/*
    input: Vec<FuncEntry> where there is one FuncEntry per function to account for.
    a FuncEntry carries a function's name, qualified path, argument list and return type (if any)
    the argument list has already been augmented to change the 'self' type to a fully qualified type
    for associated methods.

    output: TokenStream which defines the Frame enum with:
    - 1 variant for every function, with arg type
    - 1 variant for every function that has a return type
    - Stolen variant: Stolen(Arc<Mutex<Option<Frame>>>)
    - implementation of Identifiable trait for Frame enum
*/
pub fn generate_frame_enum(funcs: &Vec<FuncEntry>) -> TokenStream {
    let mut enum_variants = Vec::new();
    let mut identifiable_branches = Vec::new();

    for func in funcs.iter() {
        let func_name = &func.name;
        let arg_types = &func.args;
        
        // convert to PascalCase to avoid warnings
        let pascal_func = snake_to_pascal(func_name.to_string());

        // create enum types
        let args_tuple = if arg_types.is_empty() {
            quote! ()
        } else {
            quote! { #(#arg_types),* }
        };

        let arg_variant_name = syn::Ident::new(&format!("Input{}", pascal_func), func_name.span());
        let arg_variant = quote!(#arg_variant_name(usize, #args_tuple));
        enum_variants.push(arg_variant);

        // if let Frame::Input___(uid, ..) = self { return *uid; }
        let identifiable_branch = quote!(if let __Frame__::#arg_variant_name(uid, ..) = self { return *uid; });
        identifiable_branches.push(identifiable_branch);

        if let Some(ret_ty) = &func.ret {
            let ret_variant_name = syn::Ident::new(&format!("Output{}", pascal_func), func_name.span());
            let ret_variant = quote!(#ret_variant_name(#ret_ty));
            enum_variants.push(ret_variant);
        }
    }
    
    // generate the full enum definition
    quote! {
        pub(crate) enum __Frame__ {
            Stolen(std::sync::Arc<std::sync::Mutex<Option<__Frame__>>>),
            #(#enum_variants),*
        }

        impl velvet::Identifiable for __Frame__ {
            fn get_id(&self) -> usize {
                #(#identifiable_branches)*
                return 0;
            }
        }
    }
}

/*
    input: Vec<FuncEntry> with functions to account for
    output: app-specific steal-function

    fn steal(worker: &mut VelvetWorker<Frame>) {
        let stealers = &worker.stealers;
        let len = stealers.len();
        let mut n = worker.get_random(len);

        let result_slot = Arc::new(Mutex::new(None));
        let mut lock = result_slot.lock().unwrap();
        for _ in 0..len {
            let maybe_frame = stealers[n].steal(Frame::Stolen(result_slot.clone()));

            if let Some(frame) = maybe_frame {
                match frame {
                    Frame::InputFuncX(_, a0, a1, a2, ...) => {
                        func_x(worker, a0, a1, a2, ...);
                        *lock = None;
                    },
                    Frame::InputFuncY(_, a0, ...) => {
                        let result = func_y(worker, a0, ...);
                        *lock = Frame::OutputFuncY(result);
                    },
                    _ => panic!("WRONG STOLEN WORK FRAME!"),
                }

                return;
            }
            n = (n + 1) % len;
        }
    }
*/
pub fn generate_steal_func(funcs: &Vec<FuncEntry>) -> TokenStream {
    let specific_steal_logic = generate_steal_logic(funcs);    
    #[cfg(any(feature = "stealbackhash", feature = "stealbackvector"))]
    quote!{
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
            let mut pick_hashed = |worker: &velvet::VelvetWorker<__Frame__>,
                                victim: usize,
                                candidates: &mut Vec<usize>|
            -> usize {
                candidates.clear();
                candidates.push(victim);
                worker.stealers[victim].extend_with_workers(candidates, _id);
                candidates[worker.get_random_withself(candidates.len())]
            };

            // Compute `candidates` once (lazily) and reuse the buffer on every retry.
            
            let has_owner = worker.stealers[_id].get_owner().is_some();

            let mut n = match worker.steal_back() {
                Some(i) => {
                    stealback = true;
                    i
                },
                None => {
                    if has_owner {
                        #[cfg(feature = "hashing")]
                        {
                            match ensure_target(worker) {
                                Some(victim) => pick_hashed(worker, victim, &mut candidates),
                                None => worker.get_random(len),
                            }
                        } 
                        #[cfg(feature = "hashing_register")]
                        {
                            if let Some(victim) = worker.get_victim(){
                                victim
                            }else{
                                worker.get_random(len)
                            }
                        }    
                        #[cfg(not(any(feature = "hashing", feature ="hashing_register")))]
                        worker.get_random(len)
                    } else {
                        0
                    }
                }
            };

            

            for _ in 0..len {
                let stealer = worker.stealers[n].clone();
                #[cfg(feature = "mugging")]
                {
                    if stealback{           
                        let mut amount_task = stealer.length();

                        #[cfg(feature = "stats")]
                        let mut first = true;

                        for _task in 0..amount_task{
                            let result_slot_mugging = std::sync::Arc::new(std::sync::Mutex::new(None));
                            let mut lock = result_slot_mugging.lock().unwrap();
                            
                            let maybe_frame =
                                stealer.steal(__Frame__::Stolen(result_slot_mugging.clone()));
                            
                            #[cfg(feature = "stats")]
                            worker.add_steal_attempts(1);
                            if let Some(frame) = maybe_frame {
                                
                                #[cfg(feature = "stats")]
                                {
                                    if first{
                                        worker.add_steal_waittime(__steal_start.elapsed());
                                    }
                                }
                                
                                match frame {
                                    #specific_steal_logic
                                }

                                #[cfg(feature = "stats")]{
                                    worker.add_successful_steals(1);
                                    if first{
                                        worker.add_successful_stealback(1);
                                        first = false;
                                    }
                                }
        
                            }
                            amount_task = stealer.length();   
                        }

                        worker.unsuccessfullsteal(n);
                        n = match worker.steal_back() {
                            Some(i) => {
                                stealback = true;
                                i
                            },
                            None => {
                                stealback = false;
                                worker.get_random(len)
                            }
                        };
                        continue;
                    }
                }
                
                let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
                let mut lock = result_slot.lock().unwrap();

                
                let maybe_frame = worker.stealers[n].steal(__Frame__::Stolen(result_slot.clone()));
                #[cfg(feature = "stats")]
                worker.add_steal_attempts(1);


                if let Some(frame) = maybe_frame {
                    #[cfg(feature = "stats")]
                    worker.add_steal_waittime(__steal_start.elapsed());

                    if !stealback {
                        match worker.stealers[n].get_owner() {
                            Some(i) => {
                                worker.stealers[i].successfullsteal(_id);
                                worker.stealers[_id].set_owner(i, _id);
                            },
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
                        #specific_steal_logic
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
                        },
                        None => {
                            stealback = false;
                            #[cfg(feature = "hashing")]
                            {
                                match ensure_target(worker) {
                                    Some(victim) => pick_hashed(worker, victim, &mut candidates),
                                    None => worker.get_random(len),
                                }
                            }
                            #[cfg(feature = "hashing_register")]
                            {
                                if let Some(victim) = worker.get_victim(){
                                    victim
                                }else{
                                    worker.get_random(len)
                                }
                            }    
                            #[cfg(not(any(feature = "hashing", feature ="hashing_register")))]
                            worker.get_random(len)
                        }
                    };
                } else if !has_owner {
                    n = 0;
                } else {
                    #[cfg(not(any(feature = "hashing", feature ="hashing_register")))]
                    {
                        n = (n+1)%len; 
                    }
                    #[cfg(feature = "hashing")]
                    {
                        n = match ensure_target(worker) {
                            Some(victim) => pick_hashed(worker, victim, &mut candidates),
                            None => worker.get_random(len),
                        };
                    }
                    #[cfg(feature = "hashing_register")]
                    {
                        if let Some(victim) = worker.get_victim(){
                            n = victim;
                        }else{
                            n = (n+1)%len;   
                        }
                    }
                }
            }

            #[cfg(feature = "stats")]
            worker.add_steal_waittime(__steal_start.elapsed());
        }
    }

    
    
    #[cfg(all(not(feature = "stealbackvector"), not(feature = "stealbackhash"), feature = "topology"))]
    quote!{
        fn __velvet_steal__(worker: &mut velvet::VelvetWorker<__Frame__>) {
            #[cfg(feature = "stats")]
            let __steal_start = std::time::Instant::now();
            
            let stealers = &worker.stealers;
            let _id = worker.get_id();
            let len = stealers.len();
            let coreid = worker.get_cpuset();
            
            let mut n;
            let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));  
            let mut lock = result_slot.lock().unwrap();
            match coreid{
                Some(ids) => {
                    let cores = &ids;
                    let amount = cores.len();
                                    
                    #[cfg(feature = "priority")]
                    {
                        let mut victim: Option<usize> = None;
                        let mut size = 0;
                        for i in 0.. amount{
                            let len = stealers[i].length();
                            if  len > size{
                                victim  = Some(i);
                                size = len;
                            }
                        }
                
                        if let Some(v) = victim {
                            let stealer = worker.stealers[v].clone();
                            let maybe_frame = stealer.steal(__Frame__::Stolen(result_slot.clone()));
                            #[cfg(feature = "stats")]
                            worker.add_steal_attempts(1);
                            if let Some(frame) = maybe_frame {
                                #[cfg(feature = "stats")]
                                worker.add_steal_waittime(__steal_start.elapsed());
                                
                                match frame {
                                    #specific_steal_logic
                                }
                                
                                #[cfg(feature = "stats")]
                                worker.add_successful_steals(1);

                                return;
                            }
                        }
                    }
                    let stealers = worker.stealers.clone();
                    let mut tried: Vec<usize> = Vec::new();
                    n = worker.get_random_withself(amount);
                    for _i in 0.. amount{   
                        let id = &cores[n];                      
                        if id != _id {
                            let stealer  = worker.stealers[*id].clone();
                            if stealer.ready(){  
                                let maybe_frame =
                                    stealer.steal(__Frame__::Stolen(result_slot.clone()));
                                
                                #[cfg(feature = "stats")]
                                worker.add_steal_attempts(1);
                                
                                if let Some(frame) = maybe_frame {
                                    #[cfg(feature = "stats")]
                                    worker.add_steal_waittime(__steal_start.elapsed());
                                    
                                    match frame {
                                        #specific_steal_logic
                                    }

                                    #[cfg(feature = "stats")]
                                    worker.add_successful_steals(1);

                                    return;
                                
                                }     
                            }
                            tried.push(*id);
                        }
                        n = (n+1)%amount; 
                    }
                    n = worker.get_random(len);
                    for _i in 0..len {
                        if !(tried.contains(&n)){
                            let stealer = worker.stealers[n].clone();

                            let maybe_frame = stealer.steal(__Frame__::Stolen(result_slot.clone()));
                            
                            #[cfg(feature = "stats")]
                            worker.add_steal_attempts(1);

                            if let Some(frame) = maybe_frame {
                                #[cfg(feature = "stats")]
                                worker.add_steal_waittime(__steal_start.elapsed());
                                
                                match frame {
                                    #specific_steal_logic
                                }

                                #[cfg(feature = "stats")]
                                worker.add_successful_steals(1);
  
                                return;
                            } 
                        }     
                        n = (n+1)%len;
                    }
                }
                None => { 
                    n = worker.get_random(len);
                    for _i in 0..len {
                        
                        let stealer = worker.stealers[n].clone();
                        
                        let maybe_frame = stealer.steal(__Frame__::Stolen(result_slot.clone()));

                        #[cfg(feature = "stats")]
                        worker.add_steal_attempts(1);
                        
                        if let Some(frame) = maybe_frame {
                            #[cfg(feature = "stats")]
                            worker.add_steal_waittime(__steal_start.elapsed());
                            
                            match frame {
                                #specific_steal_logic
                            }

                            #[cfg(feature = "stats")]
                            worker.add_successful_steals(1);
                            
                            return;
                        }
                        n = (n+1)%len; 
                    }
                 }
            }
            #[cfg(feature = "stats")]
            worker.add_steal_waittime(__steal_start.elapsed());   
        }
    }
     #[cfg(all(not(feature = "stealbackvector"), not(feature = "stealbackhash"), not(feature = "topology"), feature = "register"))]
    quote!{
        fn __velvet_steal__(worker: &mut velvet::VelvetWorker<__Frame__>) {
            #[cfg(feature = "stats")]
            let steal_start = std::time::Instant::now();
           
            let _id = worker.get_id();
            let stealers = &worker.stealers;
            let len = stealers.len();  
            

            //let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));  
            //let mut lock = result_slot.lock().unwrap();             
            for _ in 0..len{
                let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));
                let mut lock = result_slot.lock().unwrap();
                
                if let Some(target) = worker.get_victim(){
                    let maybe_frame = worker.stealers[target].steal(__Frame__::Stolen(result_slot.clone())); 
                    
                    #[cfg(feature = "stats")]
                    worker.add_steal_attempts(1);
                
                    if let Some(frame) = maybe_frame {
                        #[cfg(feature = "stats")]
                        worker.add_steal_waittime(steal_start.elapsed());

                        match frame {
                            #specific_steal_logic
                        }
                        
                        #[cfg(feature = "stats")]
                        {
                            worker.add_successful_steals(1);
                        }
                       
                        return;
                    }
                }else{
                    return
                }
            }
            

            #[cfg(feature = "stats")]
            worker.add_steal_waittime(steal_start.elapsed());
        }
    }


     #[cfg(all(not(feature = "topology"), not(feature = "stealbackvector"), not(feature = "stealbackhash"),  not(feature = "register")))]
    quote!{
        fn __velvet_steal__(worker: &mut velvet::VelvetWorker<__Frame__>) {
            #[cfg(feature = "stats")]
            let steal_start = std::time::Instant::now();
           
            let _id = worker.get_id();
            let stealers = &worker.stealers;
            let len = stealers.len();  
            let mut n = worker.get_random(len);
            let result_slot = std::sync::Arc::new(std::sync::Mutex::new(None));  
            let mut lock = result_slot.lock().unwrap();

            #[cfg(feature = "priority")]
            {
                let mut victim: Option<usize> = None;
                let mut size = 0;
                for _i in 0.. len{
                    let length = stealers[n].length();
                    if  length > size{
                        victim  = Some(n);
                        size = length;
                    }
                    n = (n+1)%len; 
                    
                }    
                if let Some(v) = victim {
                    let maybe_frame = stealers[v].steal(__Frame__::Stolen(result_slot.clone()));
                    #[cfg(feature = "stats")]
                    worker.add_steal_attempts(1);
                    
                    if let Some(frame) = maybe_frame {
                        #[cfg(feature = "stats")]
                        worker.add_steal_waittime(steal_start.elapsed());
                        
                        match frame {
                            #specific_steal_logic
                        }
                        #[cfg(feature = "stats")]
                        worker.add_successful_steals(1);
                    
                        
                        return;
                    }
                }
                 n = worker.get_random(len);
            }

           
                               
            for _ in 0..len{
                #[cfg(feature = "mugging")]
                {
                    let stealer = worker.stealers[n].clone();
                    let mut amount_task = stealer.length();

                    #[cfg(feature = "stats")]
                    let mut first = true;

                    for _task in 0..amount_task{
                        let result_slot_mugging = std::sync::Arc::new(std::sync::Mutex::new(None));
                        let mut lock = result_slot_mugging.lock().unwrap();
                        
                        let maybe_frame =
                            stealer.steal(__Frame__::Stolen(result_slot_mugging.clone()));
                        
                        #[cfg(feature = "stats")]
                        worker.add_steal_attempts(1);
                        if let Some(frame) = maybe_frame {
                            
                            #[cfg(feature = "stats")]
                            {
                                if first{
                                    worker.add_steal_waittime(steal_start.elapsed());
                                }
                            }
                            
                            match frame {
                                #specific_steal_logic
                            }

                            #[cfg(feature = "stats")]{
                                worker.add_successful_steals(1);
                                if first{
                                    first = false;
                                }
                            }
    
                        }
                            amount_task = stealer.length();   
                        }

                        n = (n+1)%len; 
                }

                #[cfg(not(feature = "mugging"))]
                { 
                    let maybe_frame = worker.stealers[n].steal(__Frame__::Stolen(result_slot.clone()));  
            
                    #[cfg(feature = "stats")]{}
                    worker.add_steal_attempts(1);
                
                
                
                    if let Some(frame) = maybe_frame {
                        #[cfg(feature = "stats")]
                        worker.add_steal_waittime(steal_start.elapsed());
                    

                        match frame {
                            #specific_steal_logic
                        }
                        
                        #[cfg(feature = "stats")]
                        {
                            worker.add_successful_steals(1);
                        }                    
                        return;
                    }
                    n = (n+1)%len;
                } 
            }

            #[cfg(feature = "stats")]
            worker.add_steal_waittime(steal_start.elapsed());
        }
    }

}




/*
    input: Vec<FuncEntry> where there is one FuncEntry per function to account for.
    output: the function-specific part of the steal logic as a TokenStream.
            for every function in funcs, have a match arm for Frame::FrameFunc(args...)
            and the logic to execute, namely calling the corresponding function with the arguments
            (in case of the augmented 'self' arg, add it as a reference to the Arc)
            and sending back the done-signal with return value (if any)
*/ 
fn generate_steal_logic(funcs: &Vec<FuncEntry>) -> TokenStream {
    let mut match_statements = Vec::new();

    for func in funcs {
        let func_name = &func.name;
        let func_path = &func.path;

        // convert to pascalcase to avoid warnings
        let pascal_func = snake_to_pascal(func_name.to_string());
        let frame_name = syn::Ident::new(&format!("Input{}", pascal_func), func_name.span());
        
        let ret_variable;
        let done;
        if let Some(_) = &func.ret {
            let res_frame = syn::Ident::new(&format!("Output{}", pascal_func), func_name.span());
            ret_variable = quote!(let result = );
            done = quote!(*lock = Some(__Frame__::#res_frame(result)));
        } else {
            ret_variable = quote!();
            done = quote!(*lock = None);
        }

        if !func.args.is_empty() {
            if func.has_selfarg {
                // the first argument is the selftype!
                let selftype = syn::Ident::new("a0", Span::call_site());
                let mut frame_args = Vec::new();
                let mut func_args = Vec::new();
                for i in 1..func.args.len() {
                    let arg_name = syn::Ident::new(&format!("a{}", i), Span::call_site());
                    frame_args.push(quote!(#arg_name));
                    func_args.push(quote!(#arg_name));
                }
                let frame_args_pattern = quote! { #(#frame_args),* };
                let func_args_pattern = quote! { #(#func_args),* };

                let stmt = quote! {
                    __Frame__::#frame_name(_, a0, #frame_args_pattern) => {
                        #ret_variable #selftype.#func_name(worker, #func_args_pattern);
                        #done;
                    }
                };
                match_statements.push(stmt);
            } else {
                let mut frame_args = Vec::new();
                let mut func_args = Vec::new();
                for i in 0..func.args.len() {
                    let arg_name = syn::Ident::new(&format!("a{}", i), Span::call_site());
                    frame_args.push(quote!(#arg_name));
                    func_args.push(quote!(#arg_name));
                }
                let frame_args_pattern = quote! { #(#frame_args),* };
                let func_args_pattern = quote! { #(#func_args),* };

                let stmt = quote! {
                    __Frame__::#frame_name(_, #frame_args_pattern) => {
                        #ret_variable #func_path(worker, #func_args_pattern);
                        #done;
                    },
                };
                match_statements.push(stmt);
            }
        } else {
            let stmt = quote! (
                __Frame__::#frame_name(_) => {
                    #ret_variable #func_path(worker);
                    #done;
                }
            );
            match_statements.push(stmt);
        }
    }

    quote! {
        #(#match_statements)*
        _ => panic!("WRONG STOLEN WORK FRAME!"),
    }
}

// utility to convert from snake_case to PascalCase
fn snake_to_pascal(input: String) -> String {
    let mut result = String::new();
    let mut uppercase_next = true;

    for (i, c) in input.chars().enumerate() {
        if c == '_' {
            uppercase_next = true;
        } else if uppercase_next {
            result.push(c.to_ascii_uppercase());
            uppercase_next = false;
        } else if i == 0 {
            result.push(c.to_ascii_lowercase());
        } else {
            result.push(c);
        }
    }

    result
}