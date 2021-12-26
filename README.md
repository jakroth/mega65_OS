This is a rudimentary operating system I wrote for the Mega65 (a modern offshoot of the Commodore 64). 

Built for the topic Operating Systems in 2019 at Flinders University. 

Uses the Kick-C compiler and the xmega65 emulator. Both need to be installed to run these files. 

The src_kc folder contains code written in kickC, and handles:  
-Bootstraping and hardware initialisation  
-Application Binary Interfaces  
-Process Descriptor Blocks and context switching  
-Inter-Process Communications  

The src_c folder contains code written in C, and handles:  
-File Systems
