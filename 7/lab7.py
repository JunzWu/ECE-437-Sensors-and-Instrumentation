# -*- coding: utf-8 -*-
"""
Created on Mon Oct 14 09:16:08 2019

@author: haoxuan8
"""

# -*- coding: utf-8 -*-

#%%
# import various libraries necessery to run your Python code
import time   # time related library
import sys    # system related library
ok_loc = 'C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\3.6\\x64'
sys.path.append(ok_loc)   # add the path of the OK library
import ok     # OpalKelly library

#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communicaiton with the OK board
ConfigStatus=dev.ConfigureFPGA("U:\ece437\Lab_5_2\Lab_5_2.runs\impl_1\SPI_Transmit.bit"); # Configure the FPGA with this bit file

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
print("----------------------------------------------------")


D1 = 1
D2 = 1
A1 = 79
A2 = 78
clk_th = 10
dev.SetWireInValue(0x00, D1) 
dev.SetWireInValue(0x01, D2) 
dev.SetWireInValue(0x02, A1) 
dev.SetWireInValue(0x03, A2) 
dev.SetWireInValue(0x04, clk_th) 
dev.UpdateWireIns()  # Update the WireIns

print("button 2")
# First recieve data from the FPGA by using UpdateWireOuts
while(1):
    dev.UpdateWireOuts()
    result1 = dev.GetWireOutValue(0x20)  
    result2 = dev.GetWireOutValue(0x21)  
    value = result2+result1*256
    k = 13*(200/(clk_th*2))/25
    b = 4900*(200/(clk_th*2))/25
    print((value-b)/k)
    #print("address "+str(A1)+" : " + str(result1))
    #print("address "+str(A2)+" : " + str(result2))
    time.sleep(0.1)

dev.Close
    
#%%