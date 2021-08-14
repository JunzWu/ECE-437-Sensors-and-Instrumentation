`timescale 1ns / 1ps

module JTEG_Test_File(
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,  
    output ADT7420_A0,
    output ADT7420_A1,
    output I2C_SCL_0,
    inout I2C_SDA_0 
);

    wire  ILA_Clk, ACK_bit, FSM_Clk, TrigerEvent;    
    wire [23:0] ClkDivThreshold = 1_000;   
    wire SCL, SDA; 
    wire [7:0] State;
    wire [7:0] MSB;
    wire [7:0] LSB;
    assign TrigerEvent = button[3];

    //Instantiate the module that we like to test
    I2C_Transmit I2C_Test1 (
        .button(button),
        .led(led),
        .sys_clkn(sys_clkn),
        .sys_clkp(sys_clkp),
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        .I2C_SCL_0(I2C_SCL_0),
        .I2C_SDA_0(I2C_SDA_0),             
        .FSM_Clk_reg(FSM_Clk),        
        .ILA_Clk_reg(ILA_Clk),
        .ACK_bit(ACK_bit),
        .SCL(SCL),
        .SDA(SDA),
        .State(State),
        .MSB(MSB),
        .LSB(LSB)
        );
    
    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(ILA_Clk),
        .probe0({led, SDA, SCL, ACK_bit, State,MSB, LSB}),                             
        .probe1({FSM_Clk, TrigerEvent})
        );                        
endmodule