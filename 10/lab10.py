# -*- coding: utf-8 -*-
"""
Created on Sat Nov  9 15:24:20 2019

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

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communicaiton with the OK board
ConfigStatus=dev.ConfigureFPGA("U:\ece437\project_10\project_10.runs\impl_1\I2C_Transmit.bit"); # Configure the FPGA with this bit file

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



#acceleration
dev.SetWireInValue(0x00,0) 
dev.UpdateWireIns()

while(1):
    #acceleration
    dev.SetWireInValue(0x00,2) #WRITE
    dev.SetWireInValue(0x01,0b00110010)
    dev.SetWireInValue(0x02,0b00110011) 
    dev.SetWireInValue(0x03,0x20) 
    dev.SetWireInValue(0x04,0b10010111) 
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x28) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    XLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x29) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    XHA = dev.GetWireOutValue(0x25)
    
    #Y
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x2A) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    YLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x2B) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    YHA = dev.GetWireOutValue(0x25)
    
    #Z
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x2C) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    ZLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0x2D) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    ZHA = dev.GetWireOutValue(0x25)
    
    print(XHA, XLA)
    print(YHA, YLA)
    print(ZHA, ZLA)
    X = XHA*256 +XLA
    if X > 32768:
        X = X - 65536
    
    Y = YHA*256 + YLA
    if Y > 32768:
        Y = Y - 65536
        
    Z = ZHA*256 + ZLA
    if Z > 32768:
        Z = Z - 65536    
        
    print("x:%.2f"%(X/16*0.001))
    print("y:%.2f"%(Y/16*0.001))
    print("z:%.2f"%(Z/16*0.001))
    time.sleep(1)
    print("-----------------")



dev.SetWireInValue(0x00,2) #WRITE
dev.SetWireInValue(0x01,0b00111100)
dev.SetWireInValue(0x02,0b00111101) 
dev.SetWireInValue(0x03,0x02) 
dev.SetWireInValue(0x04,0b00000000) 
dev.UpdateWireIns()
dev.SetWireInValue(0x00,0)
dev.UpdateWireIns()


while(1):
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x01,0b00111100)
    dev.SetWireInValue(0x02,0b00111101) 
    dev.SetWireInValue(0x03,0b00000011) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    XLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0b00000100) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    XHA = dev.GetWireOutValue(0x25)
    
    #Y
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0b00000101) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    YLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0b00000110) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    YHA = dev.GetWireOutValue(0x25)
    
    #Z
    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0b00000111) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    ZLA = dev.GetWireOutValue(0x25)

    dev.SetWireInValue(0x00,0)
    dev.UpdateWireIns()
    dev.SetWireInValue(0x00,1)
    dev.SetWireInValue(0x03,0b00001000) 
    dev.UpdateWireIns()  
    time.sleep(0.01)   
    dev.UpdateWireOuts()
    ZHA = dev.GetWireOutValue(0x25)
    
    print(XHA, XLA)
    print(YHA, YLA)
    print(ZHA, ZLA)
    X = XHA*256 + XLA
    if X > 32768:
        X = X - 65536
    
    Y = YHA*256 + YLA
    if Y > 32768:
        Y = Y - 65536
        
    Z = ZHA*256 + ZLA
    if Z > 32768:
        Z = Z - 65536 
    
    
        
    print("x:%.2f"%(X/980))
    print("y:%.2f"%(Y/980))
    print("z:%.2f"%(Z/1100))
    time.sleep(1)
    print("-----------------")
 