`timescale 1ns / 1ps

module JTEG_Test_File(
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,  
    output ADT7420_A0,
    output ADT7420_A1,
    output CVM300_SPI_CLK,
    output CVM300_SPI_EN,
    output  CVM300_SPI_IN, 
    input  CVM300_SPI_OUT
);

    wire  ILA_Clk, ACK_bit, FSM_Clk, TrigerEvent;    
    wire [23:0] ClkDivThreshold = 1_000;   
    wire SPI_CLK, SPI_EN,SPI_IN,SPI_OUT; 
    wire [7:0] State;
    wire [7:0] MSB;
    wire [7:0] LSB;
    wire flag;
    wire RW;
    assign TrigerEvent = button[3];

    //Instantiate the module that we like to test
    SPI_Transmit SPI_Test1 (
        .button(button),
        .led(led),
        .sys_clkn(sys_clkn),
        .sys_clkp(sys_clkp),
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        .CVM300_SPI_CLK(CVM300_SPI_CLK),
        .CVM300_SPI_EN(CVM300_SPI_EN),  
        .CVM300_SPI_IN(CVM300_SPI_IN),
        .CVM300_SPI_OUT(CVM300_SPI_OUT),           
        .FSM_Clk_reg(FSM_Clk),        
        .ILA_Clk_reg(ILA_Clk),
        .State(State),
        .MSB(MSB),
        .LSB(LSB),
        .RW(RW),
        .flag(flag)
        );
    
    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(ILA_Clk),
        .probe0({CVM300_SPI_CLK, CVM300_SPI_EN, CVM300_SPI_IN, SPI_OUT, State,MSB, LSB, flag, RW}),                             
        .probe1({FSM_Clk, TrigerEvent})
        );                        
endmodule