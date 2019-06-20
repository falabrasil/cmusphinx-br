# CMU Sphinx - tutorial for training acoustic models

[Paper](https://www.isca-speech.org/archive/IberSPEECH_2018/abstracts/IberS18_P1-13_Batista.html): **Baseline Acoustic Models for Brazilian Portuguese Using Kaldi Tools**    
A comparison between Kaldi and CMU Sphinx for Brazilian Portuguese was
performed. Resources for both toolkits were developed and made publicly 
available to the community.
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

## Citation

If you use these codes or want to mention the paper referred above, please 
cite us as one of the following: 

> Batista, C., Dias, A.L., Sampaio Neto, N. (2018) Baseline Acoustic Models for
> Brazilian Portuguese Using Kaldi Tools. Proc. IberSPEECH 2018, 77-81, DOI:
> 10.21437/IberSPEECH.2018-17.

```bibtex
@inproceedings{Batista2018,
    author    = {Cassio Batista and Ana Larissa Dias and Nelson {Sampaio Neto}},
    title     = {{Baseline Acoustic Models for Brazilian Portuguese Using Kaldi Tools}},
    year      = {2018},
    booktitle = {Proc. IberSPEECH 2018},
    pages     = {77--81},
    doi       = {10.21437/IberSPEECH.2018-17},
    url       = {http://dx.doi.org/10.21437/IberSPEECH.2018-17}
}
```    

[![FalaBrasil](doc/logo_fb_github_footer.png)](https://ufpafalabrasil.gitlab.io/ "Visite o site do Grupo FalaBrasil") [![UFPA](doc/logo_ufpa_github_footer.png)](https://portal.ufpa.br/ "Visite o site da UFPA")

__Grupo FalaBrasil (2019)__ - https://ufpafalabrasil.gitlab.io/      
__Universidade Federal do Pará (UFPA)__ - https://portal.ufpa.br/     
Cassio Batista - cassio.batista.13@gmail.com
