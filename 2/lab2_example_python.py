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
ConfigStatus=dev.ConfigureFPGA("lab2_example.bit"); # Configure the FPGA with this bit file

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
# Define the two variables that will send data to the FPGA
# We will use WireIn instructions to send data to the FPGA

clkdiv = 100000
print("clkdiv is initilized to " + str(int(clkdiv)))
dev.SetWireInValue(0x00, clkdiv) #Input data for Variable 1 using mamoery spacee 0x00
dev.UpdateWireIns()  # Update the WireIns

'''
variable_2 = 14; # # variable_2 is initilized to digitla number 14
print("Variable 2 is initilized to " + str(int(variable_2)))

dev.SetWireInValue(0x01, variable_2) #Input data for Variable 2 using mamoery spacee 0x01

#%% 
# We will read data from the FPGA in two different variables
# Since we are using a slow clock on the FPGA to compute the results
# we need to wait for the resutl to be computed
#time.sleep(0.5)                 
'''

# First recieve data from the FPGA by using UpdateWireOuts

dev.UpdateWireOuts()
pre_result = dev.GetWireOutValue(0x20)  # Transfer the recived data in result_sum variable
#result_difference = dev.GetWireOutValue(0x21)  # Transfer teh recived data in result_difference variable
print("The counter is " + str(int(pre_result))) 
#print("The difference between the two numbers is " + str(int(result_difference))) 

while 1:
    reset=0
    dev.UpdateWireOuts()
    result=dev.GetWireOutValue(0x20)
    if result!=pre_result:
        print("The counter is " + str(int(result)))
        pre_result=result
    if result>=100:
        reset = 1; 
        #print("reset counter")
    dev.SetWireInValue(0x01, reset)
    dev.UpdateWireIns()
    time.sleep(0.1)



dev.Close
    
#%%