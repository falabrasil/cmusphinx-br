# CMU Sphinx - tutorial para treino de modelo acústico

According to CMUSphinx's [tutorial AM](https://cmusphinx.github.io/wiki/tutorialam/),
the directory tree for new projects must follow the structure below:

```
             my_db_dir/
                 │ 
  .--------------:--------------.
  │                             │                        
 etc/                          wav/                                     
  ├─ my_db.dic                  ├─ spkr_1/                     
  ├─ my_db.phone                │   ├─ s1_file_1.wav                     
  ├─ my_db.lm.DMP               │   ├─ s1_file_2.wav         
  ├─ my_db.filler               │   └─ s1_file_n.wav              
  ├─ my_db.train.fileids        ├─ spkr_2/                
  ├─ my_db.train.transcription  │   ├─ s2_file_1.wav             
  ├─ my_db.test.fileids         │   ├─ s2_file_2.wav                     
  └─ my_db.test.transcription   │   └─ s2_file_n.wav                   
                                └─ spkr_n/           
                                    ├─ sn_file_1.wav 
                                    ├─ sn_file_2.wav 
                                    └─ sn_file_n.wav 
```

* __fb\_00\_create\_envtree.sh__:
This script creates the directory structure shown above, except the `spkr_X`
inside the `wav` folder. Notice that the data-dependent files (inside the `etc` 
dir), although created, they __DO NOT__ have any content yet. IOW, they're only
initialized as empty files. A stupid choice of the developer.

* __fb\_01\_split\_train\_test.sh__:
This script fulfills the `fileids` and `transcriptions` files in `etc/` dir.
The data is divided as training set and test set, and the files within the
dirs are data-dependent. The folders `wav/spkr_X` contain symbolic links to the
actual wav-transcription base dir.

* __fb\_02\_define\_etclang.sh__:
This script specially fulfills the files inside `my_db_dir/etc` dir: .dic,
.filler and .phone. A dependency is the `g2p` software, which must be installed
and have its location available on the PATH env variable.  
__NOTE__: Unless you want to build your own dictionary, you DO NOT need to
perform this step, since the dict files you'd rather need are already on our
github repo.

__Copyright Grupo FalaBrasil (2018)__    
__Federal University of Pará__    
__Author: Cassio Batista - cassio.batista.13@gmail.com__
