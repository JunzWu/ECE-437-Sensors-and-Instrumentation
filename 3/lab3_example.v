`timescale 1ns / 1ps
module lab3_example(
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp  
    );

    reg [2:0] state = 0;
    reg [7:0] led_register = 0;
    reg [3:0] button_reg;    
    reg [28:0] counter=0;
    reg[1:0] h=0;
    reg[1:0] preG=0;
                
    wire clk;
    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    );
    
    assign led = ~led_register; //map led wire to led_register
    localparam STATE_G1R2R3      = 3'd0;
    localparam STATE_Y1R2R3      = 3'd1;
    localparam STATE_R1G2R3      = 3'd2;
    localparam STATE_R1Y2R3      = 3'd3;                 
    localparam STATE_R1R2G3      = 3'd4; 
      
    always @(posedge clk)
    begin       
        button_reg = ~button;
        begin
            case (state)
                STATE_G1R2R3 : begin
                    counter<=counter+1;
                    if (counter == 10000) begin
                        counter<=0;
                        state<= STATE_Y1R2R3;
                    end
                    led_register <= 8'b10000101;
                    if (button_reg == 4'b1000)  h<=1;                                                                     
                end

                STATE_Y1R2R3 : begin
                    counter<=counter+1;
                    if (counter == 5000) begin
                        counter<=0;
                        if (h ==1 ) begin
                            state <= STATE_R1R2G3;
                            preG=0;
                        end
                        else state<= STATE_R1G2R3;
                    end
                    led_register <= 8'b01000101;  
                    if (button_reg == 4'b1000)  h<=1;                                                                        
                end

                STATE_R1G2R3 : begin
                    counter<=counter+1;
                    if (counter == 10000) begin
                        counter<=0;
                        state<= STATE_R1Y2R3;
                    end
                    led_register <= 8'b00110001; 
                    if (button_reg == 4'b1000)  h<=1;                                                                        
                end

                STATE_R1Y2R3 : begin
                    counter<=counter+1;
                    if (counter == 5000) begin
                        counter<=0;
                        if (h==1) begin
                            state <= STATE_R1R2G3;
                            preG=1;
                        end
                        else state<= STATE_G1R2R3;
                    end
                    led_register <= 8'b00101001; 
                    if (button_reg == 4'b1000)  h<=1;                                                                       
                end
                
                STATE_R1R2G3 : begin
                    counter<=counter+1;
                    if (counter == 10000) begin
                        counter<=0;
                        h=0;
                        if (preG==0)
                            state<= STATE_R1G2R3;
                        else
                            state <= STATE_G1R2R3;
                    end
                    led_register <= 8'b00100110;                                                                          
                end
                
                default: state <= STATE_G1R2R3;
                
            endcase
        end                           
    end    
endmodule

