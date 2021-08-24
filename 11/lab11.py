# -*- coding: utf-8 -*-
"""
Created on Mon Nov 18 10:54:17 2019

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
import math

import visa

#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communicaiton with the OK board
ConfigStatus=dev.ConfigureFPGA("U:\ece437\lab11\lab11.runs\impl_1\I2C_Transmit.bit"); # Configure the FPGA with this bit file

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

#%%
# This section of the code cycles through all USB connected devices to the computer.
# The code figures out the USB port number for each instrument.
# The port number for each instrument is stored in a variable named “instrument_id”
# If the instrument is turned off or if you are trying to connect to the 
# keyboard or mouse, you will get a message that you cannot connect on that port.
device_manager = visa.ResourceManager()
devices = device_manager.list_resources()
number_of_device = len(devices)

power_supply_id = -1;
waveform_generator_id = -1;
digital_multimeter_id = -1;
oscilloscope_id = -1;

# assumes only the DC power supply is connected
for i in range (0, number_of_device):

# check that it is actually the power supply
    try:
        device_temp = device_manager.open_resource(devices[i])
        print("Instrument connect on USB port number [" + str(i) + "] is " + device_temp.query("*IDN?"))
        if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.2-6.0-2.0\r\n'):
            power_supply_id = i        
        if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.0-6.0-2.0\r\n'):
            power_supply_id = i
        if (device_temp.query("*IDN?") == 'Agilent Technologies,33511B,MY52301259,3.03-1.19-2.00-52-00\n'):
            waveform_generator_id = i
        if (device_temp.query("*IDN?") == 'Agilent Technologies,34461A,MY53207926,A.01.10-02.25-01.10-00.35-01-01\n'):
            digital_multimeter_id = i 
        if (device_temp.query("*IDN?") == 'Keysight Technologies,34461A,MY53212295,A.02.08-02.37-02.08-00.49-01-01\n'):
            digital_multimeter_id = i            
        if (device_temp.query("*IDN?") == 'KEYSIGHT TECHNOLOGIES,MSO-X 3024T,MY55100341,07.10.2017042905\n'):
            oscilloscope_id = i                        
        device_temp.close()
    except:
        print("Instrument on USB port number [" + str(i) + "] cannot be connected. The instrument might be powered of or you are trying to connect to a mouse or keyboard.\n")
    

#%%
# Open the USB communication port with the power supply.
# The power supply is connected on USB port number power_supply_id.
# If the power supply ss not connected or turned off, the program will exit.
# Otherwise, the power_supply variable is the handler to the power supply  
if (power_supply_id == -1):
    print("Power supply instrument is not powered on or connected to the PC.")    
else:
    print("Power supply is connected to the PC.")
    power_supply = device_manager.open_resource(devices[power_supply_id]) 

if (digital_multimeter_id == -1):
    print("digital_multimeter instrument is not powered on or connected to the PC.")    
else:
    print("digital_multimeter is connected to the PC.")
    digital_multimeter = device_manager.open_resource(devices[digital_multimeter_id]) 
    
if (oscilloscope_id == -1):
    print("oscilloscope instrument is not powered on or connected to the PC.")    
else:
    print("oscilloscope is connected to the PC.")
    oscilloscope = device_manager.open_resource(devices[oscilloscope_id]) 
#%%
# The power supply output voltage will be swept from 0 to 1.5V in steps of 0.05V.
# This voltage will be applied on the 6V output ports.
# For each voltage applied on the 6V power supply, we will measure the actual 
# voltage and current supplied by the power supply.
# If your circuit operates correctly, the applied and measured voltage will be the same.
# If the power supply reaches its maximum allowed current, 
# then the applied voltage will not be the same as the measured voltage.
    
power_supply.write("*CLS")
print(power_supply.write("OUTPUT ON")) # power supply output is turned on

mean_lst = []
max_lst = []
output_voltage = np.arange(3, 5.1, 0.5)

for voltage in output_voltage:
    aX = []
    aY = []
    aZ = []
    mX = []
    mY = []
    mZ = []
    acc = []
    power_supply.write("APPLy P6V, %0.2f, 0.6" % voltage)
    dev.SetWireInValue(0x07,0) 
    dev.UpdateWireIns()
    time.sleep(0.01)
    
    dev.SetWireInValue(0x05,1) 
    dev.SetWireInValue(0x06,100)
    dev.SetWireInValue(0x07,1) 
    dev.UpdateWireIns()
    
    start = time.time()
    while 1:
        #time.sleep(0.0005)   
        dev.UpdateWireOuts()
        XHA = dev.GetWireOutValue(0x20)
        YHA = dev.GetWireOutValue(0x21)
        ZHA = dev.GetWireOutValue(0x22)
        mXHA = dev.GetWireOutValue(0x23)
        mYHA = dev.GetWireOutValue(0x24)
        mZHA = dev.GetWireOutValue(0x25)
        X = XHA
        if X > 32768:
            X = X - 65536
        
        Y = YHA
        if Y > 32768:
            Y = Y - 65536
            
        Z = ZHA
        if Z > 32768:
            Z = Z - 65536    
            
        #print("x:%.2f"%(X/16*0.001))
        #print("y:%.2f"%(Y/16*0.001))
        #print("z:%.2f"%(Z/16*0.001))
        if abs(X/16*0.001) < 1:
            aX.append(X/16*0.001)
        if abs(Y/16*0.001) < 1:
            aY.append(Y/16*0.001)
        if abs(Z/16*0.001) < 1:
            aZ.append(Z/16*0.001)
        
        if abs(Y/16*0.001) < 1 and abs(Z/16*0.001) < 1:
            acc_cur = math.sqrt((Y/16*0.001)**2 + (Z/16*0.001) **2)
            acc.append(acc_cur)
        
        X = mXHA
        if X > 32768:
            X = X - 65536
        
        Y = mYHA
        if Y > 32768:
            Y = Y - 65536
            
        Z = mZHA
        if Z > 32768:
            Z = Z - 65536 
        
        
            
        #print("                    x:%.2f"%(X/980))
        #print("                    y:%.2f"%(Y/980))
        #print("                    z:%.2f"%(Z/1100))
        
        mX.append(X/980)
        mY.append(Y/980)
        mZ.append(Z/1100)
        time.sleep(0.00005)
        end = time.time()
        t = end -start
        if t>0.5:
            break
        
    time.sleep(0.01)
    dev.SetWireInValue(0x07,0) 
    dev.UpdateWireIns()
    time.sleep(0.01)
    
    dev.SetWireInValue(0x05,0) 
    dev.SetWireInValue(0x06,100)
    dev.SetWireInValue(0x07,1) 
    dev.UpdateWireIns()
    plt.figure()
    plt.plot([x for x in range(len(acc))], acc)
    plt.title("Voltage%0.2f"%voltage)
    plt.ylabel("Acceleration")
    plt.draw()
    mean = np.mean(acc)
    max_a = np.max(acc)
    mean_lst.append(mean)
    max_lst.append(max_a)
    time.sleep(2)
    


plt.figure()
plt.plot(output_voltage, mean_lst)
plt.xlabel("Voltage")
plt.ylabel("Mean Acceleration")
plt.draw()
plt.figure()

plt.plot(output_voltage, max_lst)
plt.xlabel("Voltage")
plt.ylabel("Max Acceleration")
plt.draw()
'''
start = time.time()
for i in range(250):
    #time.sleep(0.0005)   
    dev.UpdateWireOuts()
    XHA = dev.GetWireOutValue(0x20)
    YHA = dev.GetWireOutValue(0x21)
    ZHA = dev.GetWireOutValue(0x22)
    mXHA = dev.GetWireOutValue(0x23)
    mYHA = dev.GetWireOutValue(0x24)
    mZHA = dev.GetWireOutValue(0x25)
    X = XHA
    if X > 32768:
        X = X - 65536
    
    Y = YHA
    if Y > 32768:
        Y = Y - 65536
        
    Z = ZHA
    if Z > 32768:
        Z = Z - 65536    
        
    print("x:%.2f"%(X/16*0.001))
    print("y:%.2f"%(Y/16*0.001))
    print("z:%.2f"%(Z/16*0.001))
    #time.sleep(0.001)
    #print("-----------------")
    
    
    X = mXHA
    if X > 32768:
        X = X - 65536
    
    Y = mYHA
    if Y > 32768:
        Y = Y - 65536
        
    Z = mZHA
    if Z > 32768:
        Z = Z - 65536 
    
    
        
    print("                    x:%.2f"%(X/980))
    print("                    y:%.2f"%(Y/980))
    print("                    z:%.2f"%(Z/1100))
    #print("                    -----------------")
    #time.sleep(0.0004)
    
end = time.time()
t = end -start
print(t)  
'''
'''

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
'''

print(power_supply.write("OUTPUT OFF"))

# close the power supply USB handler.
# Otherwise you cannot connect to it in the future
power_supply.close()