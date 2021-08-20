# -*- coding: utf-8 -*-
"""
Created on Mon Oct 21 10:37:59 2019

@author: haoxuan8
"""

#%%
# import various libraries necessery to run your Python code
import time   # time related library
import sys    # system related library
ok_loc = 'C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\3.6\\x64'
sys.path.append(ok_loc)   # add the path of the OK library
import ok     # OpalKelly library
import matplotlib.pyplot as plt
import numpy as np 

#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communicaiton with the OK board
ConfigStatus=dev.ConfigureFPGA("U:\ece437\project_8_new\project_8_new.runs\impl_1\BTPipeExample.bit"); # Configure the FPGA with this bit file

# Check if FrontPanel is initialized correctly and if the bit file is loaded.
# Otherwise terminate the program

print("----------------------------------------------------")
if SerialStatus == 0:
    print ("FrontPanel host interface was successfully initialized.")
else:    
    print ("FrontPanel host interface not detected. The error code number is:" + str(int(SerialStatus)))
    print("Exiting the program.")
    sys.exit ()

if ConfigStatus == 0:
    print ("Your bit file is successfully loaded in the FPGA.")
else:
    print ("Your bit file did not load. The error code number is:" + str(int(ConfigStatus)))
    print ("Exiting the progam.")
    sys.exit ()
print("----------------------------------------------------")
print("----------------------------------------------------")\



#%% START-UP SEQUENCE
time.sleep(0.0001)
sys = 1
dev.SetWireInValue(0x05, sys)
dev.UpdateWireIns()
time.sleep(0.0001)
 
# SPI setting
D1 = 2
D2 = 187
D3 = 3
D4 = 9
A1 = 68 
A2 = 83
A3 = 57
A4 = 69
clk_th = 4
dev.SetWireInValue(0x04, D1) 
dev.SetWireInValue(0x01, 1) #write 
dev.SetWireInValue(0x02, A1) 
dev.SetWireInValue(0x03, clk_th) 
dev.UpdateWireIns()  # Update the WireIns

time.sleep(0.1)
dev.SetWireInValue(0x01, 0) #write 
dev.UpdateWireIns()  # Update the WireIns
time.sleep(0.1)

dev.SetWireInValue(0x04, D2) 
dev.SetWireInValue(0x01, 1) #write 
dev.SetWireInValue(0x02, A2) 
dev.UpdateWireIns()  # Update the WireIns

time.sleep(0.1)
dev.SetWireInValue(0x01, 0) #write 
dev.UpdateWireIns()  # Update the WireIns
time.sleep(0.1)

dev.SetWireInValue(0x04, D3) 
dev.SetWireInValue(0x01, 1) #write 
dev.SetWireInValue(0x02, A3) 
dev.UpdateWireIns()  # Update the WireIns

time.sleep(0.1)
dev.SetWireInValue(0x01, 0) #write 
dev.UpdateWireIns()  # Update the WireIns
time.sleep(0.1)

dev.SetWireInValue(0x04, D4) 
dev.SetWireInValue(0x01, 1) #write 
dev.SetWireInValue(0x02, A4) 
dev.UpdateWireIns()  # Update the WireIns

time.sleep(0.1)
dev.SetWireInValue(0x01, 0) #write 
dev.UpdateWireIns()  # Update the WireIns
time.sleep(0.1)

#%%


dev.SetWireInValue(0x00, 1); #Reset FIFOs and counter
dev.UpdateWireIns();  # Update the WireIns

dev.SetWireInValue(0x00, 0); #Release reset signal
dev.UpdateWireIns();  # Update the WireIns

buf = bytearray(488*648*4);
buf1 = np.zeros(488*648)
dev.ReadFromBlockPipeOut(0xa0, 256, buf); 
ind=0
for i in range (0, 488*648*4, 4):    
   result = buf[i] + (buf[i+1]<<8) + (buf[i+2]<<16) + (buf[i+3]<<24);
   buf1[ind] = int(result)
   ind+=1

img = np.array(buf1).reshape(488,648) #,order='F')
plt.imshow(img, 'gray', vmin = 0, vmax=255)


dev.Close