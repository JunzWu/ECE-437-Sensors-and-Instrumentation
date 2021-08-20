`timescale 1ns / 1ps

module SPI_Transmit(
    input sys_clkn,
    input sys_clkp,
    output CVM300_SPI_CLK,
    output CVM300_SPI_EN,
    output  CVM300_SPI_IN, 
    input  CVM300_SPI_OUT,
    input wire FSM_Clk,
    input wire [7:0] A1,
    input wire [7:0] D1,
    input wire [2:0] R_W,
    output reg [7:0] MSB
    );
    
    reg [7:0] State;
    reg FSM_Clk_reg;   
    reg SPI_CLK;
    reg SPI_EN;
    reg SPI_IN;
    wire SPI_OUT;
    
    
    //Instantiate the ClockGenerator module, where three signals are generate:
    //High speed CLK signal, Low speed FSM_Clk signal     
    reg  RW = 1'b0;
       
    localparam STATE_INIT       = 8'd0;    
    assign CVM300_SPI_CLK = SPI_CLK;
    assign CVM300_SPI_EN = SPI_EN; 
    assign CVM300_SPI_IN = SPI_IN;
    assign SPI_OUT = CVM300_SPI_OUT;
    
    initial  begin
        SPI_CLK = 1'b0;
        SPI_EN = 1'b0;
        SPI_IN = 1'b0;
        State = 8'd0;  
        MSB= 8'd0; 
    end
    
    always @(*) begin
        FSM_Clk_reg = FSM_Clk;
    end   
                               
    always @(posedge FSM_Clk) begin                       
        case (State)
            // Press Button[3] to start the state machine. Otherwise, stay in the STATE_INIT state        
            STATE_INIT : begin
                if (R_W == 2'd1) begin
                  State <= 8'd1;
                  RW <= 1; //write
                end
                else if (R_W == 2'd2) begin
                    State <= 8'd1;
                    RW <= 0;  //read     
                 end            
                else  begin                 
                      SPI_EN <= 1'b0;
                      SPI_CLK <= 1'b0;
                      State <= 8'd0;
                end
            end            
            
            // write, This is the Start sequence            
            8'd1 : begin
                  SPI_EN <= 1'b1;
                  SPI_CLK <= 1'b0;
                  if (RW == 1) SPI_IN <= 1'b1;
                  else SPI_IN <= 1'b0;
                  State <= State + 1'b1;                                
            end   
            
            8'd2 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;                 
            end   

            // transmit bit 6   
            8'd3 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[6];
                  State <= State + 1'b1;                 
            end   

            8'd4 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   
            
            //5
            8'd5 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[5];
                  State <= State + 1'b1;
            end   

            8'd6 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   

            // transmit bit 4
            8'd7 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[4];
                  State <= State + 1'b1;               
            end   

            8'd8 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   
            
            
            //3
            8'd9 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[3];
                  State <= State + 1'b1;
            end   

            8'd10 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   

            // transmit bit 2
            8'd11 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[2];
                  State <= State + 1'b1;                
            end   

            8'd12 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   
            
            //1
            8'd13 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[1];
                  State <= State + 1'b1;
            end   

            8'd14 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   

            // transmit bit 0
            8'd15 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= A1[0];
                  State <= State + 1'b1;                
            end   


            //write D
            8'd16 : begin
                  SPI_CLK <= 1'b1;
                  State <= State + 1'b1;
            end   
            
            //7
            8'd17 : begin
                  SPI_CLK <= 1'b0;
                  SPI_IN <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[7];
                  State <= State + 1'b1;
            end   

            8'd18 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[7] <= SPI_OUT;
                  State <= State + 1'b1;
            end   

            // transmit bit 6
            8'd19 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[6];
                  State <= State + 1'b1;                
            end   

            8'd20 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[6] <= SPI_OUT;
                  State <= State + 1'b1;
            end   

            //5
            8'd21 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[5];
                  State <= State + 1'b1;
            end   

            8'd22 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[5] <= SPI_OUT;
                  State <= State + 1'b1;
            end  
            
            // transmit bit 4
            8'd23 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[4];
                  State <= State + 1'b1;                
            end   

            8'd24 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[4] <= SPI_OUT;
                  State <= State + 1'b1;
            end   

            //3
            8'd25 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[3];
                  State <= State + 1'b1;
            end   

            8'd26 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[3] <= SPI_OUT;
                  State <= State + 1'b1;
            end  
 
            // transmit bit 2
            8'd27 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[2];
                  State <= State + 1'b1;               
            end   

            8'd28 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[2] <= SPI_OUT;
                  State <= State + 1'b1;
            end   

            //1
            8'd29 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[1]; 
                  State <= State + 1'b1;
            end   

            8'd30 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[1] <= SPI_OUT;
                  State <= State + 1'b1;
            end
            
            // transmit bit 0
            8'd31 : begin
                  SPI_CLK <= 1'b0;
                  if (RW == 1)
                    SPI_IN <= D1[0];
                  State <= State + 1'b1;           
            end   

            8'd32 : begin
                  SPI_CLK <= 1'b1;
                  if (RW == 0)
                    MSB[0] <= SPI_OUT;                  
                  State <= State + 1'b1;
            end   

            8'd33 : begin
                  SPI_CLK <= 1'b0;
                  State <= State + 1'b1;
            end   

            8'd34 : begin            
                    SPI_EN <= 1'b0;
                    SPI_IN <= 1'b0;
                    State <= 8'd0;
            end  
             
            //If the FSM ends up in this state, there was an error in teh FSM code
            //LED[6] will be turned on (signal is active low) in that case.
            default : begin
            end                              
        endcase                           
    end                 
endmodule
