# Atari 600XL Upgrades
A 16KB Atari 600XL was upgraded during 2015/2016 with the following additions and modifications:
1. PS/2 Keyboard
2. PC RS232 interface for file storage
3. 64k RAM memory upgrade
4. Composite video output upgrade
5. 5 volt PSU upgrade

### Completed upgraded Atari 600XL
<p align="center">
<img src="Atari600XL-Small.png" width="940" />  
<br>

### 64k RAM Memory upgrade 
Also read 64kRAMUpgrade.txt - modification is adapted from a Michigan Atari Magazine article by Don Neff.

1. Replace two existing 16kx4 dram chips with two 41464-10 64K X 4 bit Dram chips
2. Bend up three IC pins (U11 74LS51 pin 8, U5 74LS158 pin 3, U6 74LS158 pin 10
3. Unsolder one 33 ohm resistor pin R36
4. Add 3 jumper wires (yellow, red and blue in photo)

<p align="left">
<img src="64kRAMUpgrade.png" width="764" />  
<br>
<p align="left">
<img src="RAM Memory.png" width="540" />  
<br>

### PS/2 Keyboard upgrade (PIC16F84) 
Note open-source version of PIC16F84AKI.hex provided in file MageAKI1.asm.
Schematic as below - the EEPROM is not required for operation.
Refer to https://www.microchip.com/forums/m675230.aspx and https://atariage.com/forums/topic/183498-ps2-keyboard-with-8-bits/ for sources and acknowledgments.
Refer to PC2AtariKeys.txt for the Key Maps.

<p align="left">
<img src="PS2KeyboardSchematic.png" width="940" />  
<br>
<p align="left">
<img src="PS2Keyboard Interface.png" width="440" />  
<br>
<p align="left">
<img src="4051 Keyboard Interface.png" width="440" />  
<br> 
<p align="left">
<img src="PS2Keyboard Interface Large.png" width="440" />  
<br>  

### PC RS232 interface upgrade (MAX232)
<p align="left">
<img src="RS232 PC Interface.png" width="540" />  
<br>
<p align="left">
<img src="RS232 PC Interface Large.png" width="540" />  
<br>  
  
### Video output upgrade
<p align="left">
<img src="Video Output.png" width="440" />  
<br>
  
 ### PSU upgrade
<p align="left">
<img src="PSU.png" width="740" />  
<br>
  
More details to follow....
