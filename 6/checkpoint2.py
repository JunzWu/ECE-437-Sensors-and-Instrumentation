# -*- coding: utf-8 -*-

# This code reads data from the temperature sensor and outputs the results on the screen.
# The bit file programs OpalKellyâ€™s XEM7310 board with a finite state machine that implements 
# I2C protocol. With this protocol, temperature data is received from the temperature sensor
# to the FPGA. Then the FPGA transfers the data from the two registers containing 
# the temperature data to the PC using OKWireOut.

# import various libraries necessery to run your Python code
import sys    # system related library
ok_loc = 'C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\3.6\\x64'
sys.path.append(ok_loc)   # add the path of the OK library
import ok     # OpalKelly library
import visa
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import time
mpl.style.use('ggplot')


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
        if (device_temp.query("*IDN?") == 'Agilent Technologies,34461A,MY53207918,A.01.10-02.25-01.10-00.35-01-01\n'):
            digital_multimeter_id = i 
        if (device_temp.query("*IDN?") == 'Keysight Technologies,34461A,MY53213280,A.02.08-02.37-02.08-00.49-01-01\n'):
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

    
#%%
# The power supply output voltage will be swept from 0 to 1.5V in steps of 0.05V.
# This voltage will be applied on the 6V output ports.
# For each voltage applied on the 6V power supply, we will measure the actual 
# voltage and current supplied by the power supply.
# If your circuit operates correctly, the applied and measured voltage will be the same.
# If the power supply reaches its maximum allowed current, 
# then the applied voltage will not be the same as the measured voltage.
    
    # Define FrontPanel device variable, open USB communication and
    # load the bit file in the FPGA
    dev = ok.okCFrontPanel();  # define a device for FrontPanel communication
    SerialStatus=dev.OpenBySerial("");      # open USB communicaiton with the OK board
    ConfigStatus=dev.ConfigureFPGA("I2C_Temperature.bit"); # Configure the FPGA with this bit file
    
    # Check if FrontPanel is initialized correctly and if the bit file is loaded.
    # Otherwise terminate the program
    print("----------------------------------------------------")
    if SerialStatus == 0:
        print ("FrontPanel host interface was successfully initialized.");
    else:    
        print ("FrontPanel host interface not detected. The error code num ber is:" + str(int(SerialStatus)));
        print("Exiting the program.");
        sys.exit ();
    
    if ConfigStatus == 0:
        print ("Your bit file is successfully loaded in the FPGA.");
    else:
        print ("Your bit file did not load. The error code number is:" + str(int(ConfigStatus)));
        print ("Exiting the progam.");
        sys.exit ();
    print("----------------------------------------------------")
    print("----------------------------------------------------")
    
    
    output_voltage = np.arange(0.09, 4.7, 0.09)
    measured_temp=np.array([])
    measured_std=np.array([])
    
    power_supply.write("*CLS")
    print(power_supply.write("OUTPUT ON")) # power supply output is turned on
    # loop through the different voltages we will apply to the power supply
    # For each voltage applied on the power supply, 
    # measure the voltage and current supplied by the 6V power supply
    for v in output_voltage:
        # apply the desired voltage on teh 6V power supply and limist the output current to 0.5A
        power_supply.write("APPLy P6V, %0.2f, 0.6" % v)
        # pause 50ms to let things settle
        time.sleep(10)
        
        measure_temp_avg=np.array([])
        for i in range(100):
            time.sleep(0.05)
            dev.SetWireInValue(0x00, 1); #Sending 1 at memory locaiton 0x00 starts the FSM
            dev.UpdateWireIns();  # Update the WireIns    
        
            dev.UpdateWireOuts()  # Recieve the temperature data
            temperature_msb = dev.GetWireOutValue(0x20)  # MSB temperature register
            temperature_lsb = dev.GetWireOutValue(0x21)  # LSB temperature register
            temperature = ((temperature_msb<<8) + temperature_lsb)/128; # Put the temperature data together
            measure_temp_avg = np.append(measure_temp_avg, temperature)
        
        temp=np.mean(measure_temp_avg)
        std=np.std(measure_temp_avg)
        print (temp, std) # print the results
        measured_temp = np.append(measured_temp, temp)
        measured_std = np.append(measured_std, std)
        print(measured_temp)
        
    # power supply output is turned off
    print(power_supply.write("OUTPUT OFF"))
    
    # close the power supply USB handler.
    # Otherwise you cannot connect to it in the future
    power_supply.close()
    
    #%%    
    # plot results (applied voltage vs measured supplied current)
    plt.figure()
    print(measured_temp)
    print(measured_std)
    plt.plot(output_voltage,measured_temp)
    plt.title("Applied Volts vs. Measured Temperature")
    plt.xlabel("Applied Volts [V]")
    plt.ylabel("Measured Temperature")
    plt.draw()
    
    
    plt.figure()
    plt.plot(output_voltage,measured_std)
    plt.title("Applied Volts vs. Measured std")
    plt.xlabel("Applied Volts [V]")
    plt.ylabel("Measured std")
    plt.draw()
    
    # show all plots
    plt.show()
