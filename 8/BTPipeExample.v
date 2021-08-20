`timescale 1ns / 1ps

module BTPipeExample(
    input   wire    [4:0] okUH,
    output  wire    [2:0] okHU,
    inout   wire    [31:0] okUHU,
    inout   wire    okAA,
    output CVM300_SPI_CLK,
    output CVM300_SPI_EN,
    output  CVM300_SPI_IN, 
    input  CVM300_SPI_OUT,
    output CVM300_CLK_IN,
    output CVM300_Enable_LVDS,
    output CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    input CVM300_CLK_OUT,
    input CVM300_Line_valid,
    input CVM300_Data_valid,
    input [9:0] CVM300_D,
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp
    );
    
    wire okClk;            //These are FrontPanel wires needed to IO communication    
    wire [112:0]    okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0]     okEH;  //These are FrontPanel wires needed to IO communication     
    //This is the OK host that allows data to be sent or recived    
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
        
    //Depending on the number of outgoing endpoints, adjust endPt_count accordingly.
    //In this example, we have 1 output endpoints, hence endPt_count = 1.
    localparam  endPt_count = 5;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);    
    
    //Instantiate the ClockGenerator module, where three signals are generate:
    //High speed CLK signal, Low speed FSM_Clk signal     
    wire [23:0] ClkDivThreshold;   
    wire FSM_Clk, ILA_Clk; 
    ClockGenerator ClockGenerator1 (  .sys_clkn(sys_clkn),
                                      .sys_clkp(sys_clkp),                                      
                                      .ClkDivThreshold(ClkDivThreshold),
                                      .FSM_Clk(FSM_Clk),                                      
                                      .ILA_Clk(ILA_Clk) );
    
    wire [7:0] A1;
    wire [7:0] D1;
    wire [2:0] R_W;
    wire [7:0] MSB;
                                      
    SPI_Transmit SPI_transmit1 (
        .sys_clkn(sys_clkn),
        .sys_clkp(sys_clkp),
        .CVM300_SPI_CLK(CVM300_SPI_CLK),
        .CVM300_SPI_EN(CVM300_SPI_EN),
        .CVM300_SPI_IN(CVM300_SPI_IN), 
        .CVM300_SPI_OUT(CVM300_SPI_OUT),
        .FSM_Clk(FSM_Clk),
        .A1(A1),
        .D1(D1),
        .R_W(R_W),
        .MSB(MSB)
    );                                  
                                      
                                                                                  
    localparam STATE_INIT                = 8'd0;
    localparam STATE_RESET               = 8'd1;   
    localparam STATE_DELAY               = 8'd2;
    localparam STATE_RESET_FINISHED      = 8'd3;
    localparam STATE_ENABLE_WRITING      = 8'd4;
    localparam STATE_COUNT               = 8'd5;
    localparam STATE_FINISH              = 8'd6;
    
    
   
    reg [31:0] pixel_data = 8'd5;
    reg [15:0] counter_delay = 16'd0;
    reg [7:0] State = STATE_INIT;
    reg [7:0] State1 = STATE_INIT;
    reg [7:0] led_register = 0;
    reg [3:0] button_reg, write_enable_counter;  
    reg write_reset, read_reset;
    reg write_enable;
    wire [31:0] Reset_Counter;
    wire [31:0] DATA_Counter;    
    wire FIFO_read_enable, FIFO_BT_BlockSize_Full, FIFO_full, FIFO_empty, BT_Strobe;
    wire [31:0] FIFO_data_out;
    reg SYS_RES_N;
    reg FRAME_REQ;
    wire sys;
    wire frame;
    reg frame_reset;
    wire CLK_OUT;
    wire LVAL;
    wire DVAL;
    wire [9:0] pixel;
    reg line_counter = 1'd0;
    reg  r;
    reg [8:0] circulation = 9'd0;
    reg [7:0] data_r;
    
    assign led[0] = ~FIFO_empty; 
    assign led[1] = ~FIFO_full;
    assign led[2] = ~FIFO_BT_BlockSize_Full;
    assign led[3] = ~FIFO_read_enable;  
    assign led[7] = ~read_reset;
    assign led[6] = ~write_reset;
    assign CVM300_CLK_IN = ILA_Clk;
    assign CVM300_SYS_RES_N = SYS_RES_N;
    assign CVM300_FRAME_REQ = FRAME_REQ;
    assign CLK_OUT = CVM300_CLK_OUT;
    assign LVAL = CVM300_Line_valid;
    assign DVAL  = CVM300_Data_valid;
    assign pixel[9:0] = CVM300_D[9:0];
    
    initial begin
        write_reset <= 1'b0;
        read_reset <= 1'b0;
        SYS_RES_N <= 1'b1;
        FRAME_REQ <= 1'b0;
        frame_reset <= 1'b0;
        write_enable <= 1'b0;
        data_r <= 8'd0;
        r <= 1'b0;
    end
    
    always @(negedge ILA_Clk) begin
        if (sys == 1'b1) SYS_RES_N <= 1'b1;          
    end
    
    always @(negedge CLK_OUT) begin
        if (LVAL == 1'b1 && DVAL == 1'b1)begin           
            pixel_data[7:0] <= pixel[7:0];
        end
        
        
    end
    
   always @(negedge CLK_OUT) begin    
        r <= 1'b1;             
        if (Reset_Counter[0] == 1'b1) State <= STATE_RESET;
        
        case (State)
            STATE_INIT:   begin                              
                write_reset <= 1'b1;
                read_reset <= 1'b1;
                write_enable <= 1'b0;
                if (Reset_Counter[0] == 1'b1) State <= STATE_RESET;                
            end
            
            STATE_RESET:   begin
                circulation <= 0;
                counter_delay <= 0;
                write_reset <= 1'b1;
                read_reset <= 1'b1;
                write_enable <= 1'b0;                
                if (Reset_Counter[0] == 1'b0) State <= STATE_RESET_FINISHED;             
            end                                     
 
           STATE_RESET_FINISHED:   begin
                write_reset <= 1'b0;
                read_reset <= 1'b0;                 
                State <= STATE_DELAY;                                   
            end   
                          
            STATE_DELAY:   begin            
                FRAME_REQ <= 1'b1;
                if (counter_delay == 16'b0000_0000_0000_0001)begin
                    State <= STATE_COUNT;
                    FRAME_REQ<= 1'b0;
                  end
                else counter_delay <= counter_delay + 1;
                
                State <= STATE_COUNT;
            end
                                             
             STATE_COUNT:   begin             
                if (LVAL == 1'b1 && DVAL == 1'b1) begin
                    write_enable <= 1'b1;
                    data_r[7:0] <= CVM300_D[7:0];
                    circulation <= circulation + 1; 
                end else begin               
                    write_enable <= 0;
                end   
                                                 
                if (circulation == 316224)  State <= STATE_FINISH;         
             end
            
             STATE_FINISH:   begin                         
                 write_enable <= 1'b0;                                                           
            end

        endcase
    end  
       
    fifo_generator_0 FIFO_for_Counter_BTPipe_Interface (
        .wr_clk(CLK_OUT),
        .wr_rst(write_reset),
        .rd_clk(okClk),
        .rd_rst(read_reset),
        .din(pixel_data),
        .wr_en(write_enable),
        .rd_en(FIFO_read_enable),
        .dout(FIFO_data_out),
        .full(FIFO_full),
        .empty(FIFO_empty),       
        .prog_full(FIFO_BT_BlockSize_Full)        
    );
      
    okBTPipeOut CounterToPC (
        .okHE(okHE), 
        .okEH(okEHx[ 0*65 +: 65 ]),
        .ep_addr(8'ha0), 
        .ep_datain(FIFO_data_out), 
        .ep_read(FIFO_read_enable),
        .ep_blockstrobe(BT_Strobe), 
        .ep_ready(FIFO_BT_BlockSize_Full)
    );                                      
    
    okWireIn wire10 (   .okHE(okHE), 
                        .ep_addr(8'h00), 
                        .ep_dataout(Reset_Counter));   
    
    
    okWireIn wire14 (   .okHE(okHE), 
                        .ep_addr(8'h04), 
                        .ep_dataout(D1));
                      
    //  The data is communicated via memeory location 0x01                 
    okWireIn wire11 (   .okHE(okHE), 
                        .ep_addr(8'h01), 
                        .ep_dataout(R_W));
    
    okWireIn wire12 (   .okHE(okHE), 
                        .ep_addr(8'h02), 
                        .ep_dataout(A1));                                       
    
    okWireIn wire13 (   .okHE(okHE), 
                        .ep_addr(8'h03), 
                        .ep_dataout(ClkDivThreshold)); 
    
    
    okWireIn wire15 (   .okHE(okHE), 
                        .ep_addr(8'h05), 
                        .ep_dataout(sys));
                      
    okWireIn wire16 (   .okHE(okHE), 
                        .ep_addr(8'h06), 
                        .ep_dataout(frame));
                                           
    // result_wire is transmited to the PC via address 0x20   
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 1*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(MSB));    
    
    okWireOut wire21 (  .okHE(okHE), 
                        .okEH(okEHx[ 2*65 +: 65 ]),
                        .ep_addr(8'h21), 
                        .ep_datain(r));                 
                     
                                                     
endmodule
