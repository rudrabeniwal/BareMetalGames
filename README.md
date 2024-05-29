# BareMetalGames
Games implemented as a bootloader. Written in x86 assembly language, this project demonstrates the fundamentals of low-level programming, including direct hardware manipulation and real-time user input handling.  
  
Assembling the Code:  
```
-> nasm -f bin pong.asm -o pong.bin  
```  
  
Creating a Bootable Image  
To run the binary on QEMU, you need to create a bootable floppy disk image. Here's how you can do it:  
  
Create a Blank Image:  
```
dd if=/dev/zero of=floppy.img bs=512 count=2880  
```  
This creates a 1.44MB floppy disk image (2880 sectors of 512 bytes each).  
  
Write the Bootloader to the Image:  
```
dd if=pong.bin of=floppy.img conv=notrunc  
```  
Running the Image  
Run the Image using QEMU:  
```  
qemu-system-x86_64 -drive format=raw,file=floppy.img  
```
