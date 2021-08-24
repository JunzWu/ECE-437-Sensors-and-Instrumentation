`timescale 1ns / 1ps

module I2C_Transmit(
    input   wire    [4:0] okUH,
    output  wire    [2:0] okHU,
    inout   wire    [31:0] okUHU,
    inout   wire    okAA,
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,
    output ADT7420_A0,
    output ADT7420_A1,
    output I2C_SCL_1,
    inout  I2C_SDA_1,
    output PMOD_A1,
    output PMOD_A2,
    output PMOD_A7,
    output PMOD_A8     
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
    localparam  endPt_count = 6;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);
    
    reg FSM_Clk_reg;    
    reg ILA_Clk_reg;
    reg SACK_bit;
    reg SCL;
    reg SDA;
    reg A1;
    reg A2;
    reg [7:0] State;
    reg [7:0] State1;
    reg [15:0] XHA;
    reg [15:0] YHA;  
    reg [15:0] ZHA;
    reg [15:0] mXHA;
    reg [15:0] mYHA;  
    reg [15:0] mZHA;
    reg [4:0] flag;
    
    //Instantiate the ClockGenerator module, where three signals are generate:
    //High speed CLK signal, Low speed FSM_Clk signal     
    wire [23:0] ClkDivThreshold = 100;   
    wire FSM_Clk, ILA_Clk; 
    ClockGenerator ClockGenerator1 (  .sys_clkn(sys_clkn),
                                      .sys_clkp(sys_clkp),                                      
                                      .ClkDivThreshold(ClkDivThreshold),
                                      .FSM_Clk(FSM_Clk),                                      
                                      .ILA_Clk(ILA_Clk) );
    reg [1:0] RW; 
    reg [1:0] mRW;                                   
    reg [7:0] SingleByteData;
    reg [7:0] SingleByteData2;
    reg [7:0] A_W;
    reg [7:0] D;
    reg [7:0] A_R;
    reg [1:0] p_RW;
    
    wire direction;
    wire [7:0] num_pulses;
    wire enable;
    reg [7:0] cur_pulses;
    reg p_enable;
    
    reg [3:0] button_reg; 
    reg error_bit = 1'b1;      
       
    localparam STATE_INIT       = 8'd0;    
    assign led[7] = SACK_bit;
    assign led[6] = error_bit;
    assign ADT7420_A0 = 1'b0;
    assign ADT7420_A1 = 1'b0;
    assign I2C_SCL_1 = SCL;
    assign I2C_SDA_1 = SDA; 
    assign PMOD_A1 = A1; 
    assign PMOD_A2 = A2;
    assign PMOD_A7 = A1; 
    assign PMOD_A8 = A2; 
    
    initial  begin
        SCL = 1'b1;
        SDA = 1'b1;
        SACK_bit = 1'b1;
        State = 8'd0;
        State1 = 8'd0;  
        cur_pulses = 8'd0;
        XHA = 16'd0;
        YHA = 16'd0;
        ZHA = 16'd0;
        mXHA = 16'd0;
        mYHA = 16'd0;
        mZHA = 16'd0;        
        flag = 5'd0;
        p_RW = 2'd0;
        RW = 2'd2;
        mRW = 2'd2;
        p_enable = 1'b0;
        A1 = 1'b0;
        A2 = 1'b0;
        SingleByteData = 8'b00110010;
        SingleByteData2 = 8'b00110011;
        A_W = 8'b00100000;
        D = 8'b10010111;
        A_R = 8'b10101000;
    end
    
    always @(*) begin
        button_reg = ~button;  
        FSM_Clk_reg = FSM_Clk;
        ILA_Clk_reg = ILA_Clk;   
    end   
    
    always @(posedge ILA_Clk) begin
        case (State1)     
            STATE_INIT : begin
                A1 <= 0;
                A2 <= 0;
                if (enable == 1'b1 && p_enable == 1'b0)  State1 <= 8'd1; 
                else if (enable == 1'b0)  p_enable <= 1'b0;
            end            
                      
            8'd1 : begin
                A2 <= direction;
                State1 <= State1 + 1;                                  
            end
            
            8'd2 : begin
                if (A1 == 1'b0)   A1 <= 1'b1;
                else if (A1 == 1'b1)  begin
                    A1 <= 1'b0;
                    cur_pulses <= cur_pulses + 1;
                end
                
                if (cur_pulses == num_pulses) begin
                    p_enable <= 1'b1;
                    A1 <= 1'b0;
                    cur_pulses <= 0;
                    State1 <= State1 + 1; 
                end                              
            end
            
            8'd3 : begin
                State1 <= STATE_INIT;                                  
            end
        endcase
    end
                               
    always @(posedge FSM_Clk) begin                       
        case (State)
            // Press Button[3] to start the state machine. Otherwise, stay in the STATE_INIT state        
            STATE_INIT : begin               
                  SCL <= 1'b1;
                  SDA <= 1'b1;
                  flag <= 5'b0;
                  State <= 8'd1;
            end            
            
            // This is the Start sequence            
            8'd1 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b0;
                  State <= State + 1'b1;                                
            end   
            
            8'd2 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;
                  State <= State + 1'b1;                 
            end   

            // transmit bit 7   
            8'd3 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[7];
                  State <= State + 1'b1;                 
            end   

            8'd4 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd5 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd6 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 6
            8'd7 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[6];  
                  State <= State + 1'b1;               
            end   

            8'd8 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd9 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd10 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 5
            8'd11 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[5]; 
                  State <= State + 1'b1;                
            end   

            8'd12 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd13 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd14 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 4
            8'd15 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[4]; 
                  State <= State + 1'b1;                
            end   

            8'd16 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd17 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd18 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 3
            8'd19 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[3]; 
                  State <= State + 1'b1;                
            end   

            8'd20 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd21 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd22 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            // transmit bit 2
            8'd23 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[2]; 
                  State <= State + 1'b1;                
            end   

            8'd24 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd25 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd26 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
 
            // transmit bit 1
            8'd27 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[1];  
                  State <= State + 1'b1;               
            end   

            8'd28 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd29 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd30 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end
            
            // transmit bit 0
            8'd31 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData[0];      
                  State <= State + 1'b1;           
            end   

            8'd32 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd33 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd34 : begin
                  SCL <= 1'b0;                  
                  State <= State + 1'b1;
            end  
                        
            // read the ACK bit from the sensor and display it on LED[7]
            8'd35 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd36 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd37 : begin
                  SCL <= 1'b1;
                  SACK_bit <= SDA;                 
                  State <= State + 1'b1;
            end   
            

            8'd38 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            //A7
            8'd39 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[7];  
                  else if (RW == 2'd1) SDA <= A_R[7];      
                  State <= State + 1'b1; 
            end                 
                  
            8'd40 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd41 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd42 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 6
            8'd43 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[6];  
                  else if (RW == 2'd1) SDA <= A_R[6];   
                  State <= State + 1'b1;               
            end   

            8'd44 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd45 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd46 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 5
            8'd47 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[5];  
                  else if (RW == 2'd1) SDA <= A_R[5]; 
                  State <= State + 1'b1;                
            end   

            8'd48 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd49 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd50 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 4
            8'd51 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[4];  
                  else if (RW == 2'd1) SDA <= A_R[4]; 
                  State <= State + 1'b1;                
            end   

            8'd52 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd53 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd54 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 3
            8'd55 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[3];  
                  else if (RW == 2'd1) SDA <= A_R[3];
                  State <= State + 1'b1;                
            end   

            8'd56 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd57 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd58 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            // transmit bit 2
            8'd59 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[2];  
                  else if (RW == 2'd1) SDA <= A_R[2];
                  State <= State + 1'b1;                
            end   

            8'd60 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd61 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd62 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
 
            // transmit bit 1
            8'd63 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[1];  
                  else if (RW == 2'd1) SDA <= A_R[1];
                  State <= State + 1'b1;               
            end   

            8'd64 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd65 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd66 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end
            
            // transmit bit 0
            8'd67 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd2) SDA <= A_W[0];  
                  else if (RW == 2'd1) SDA <= A_R[0];  
                  State <= State + 1'b1;           
            end   

            8'd68 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd69 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd70 : begin
                  SCL <= 1'b0;                  
                  State <= State + 1'b1;
            end  
                        
            // read the ACK bit from the sensor and display it on LED[7]
            8'd71 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd72 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd73 : begin
                  SCL <= 1'b1;
                  SACK_bit <= SDA;                 
                  State <= State + 1'b1;
            end   
            

            8'd74 : begin
                  SCL <= 1'b0;
                  if (RW == 2'd1 && SingleByteData == 8'b00110010) State <= State + 1'b1;
                  else if (RW == 2'd2 && SingleByteData == 8'b00110010) State <= 8'd155;
                  else if (mRW == 2'd1 && SingleByteData == 8'b00111100) State <= State + 1'b1;
                  else if (mRW == 2'd2 && SingleByteData == 8'b00111100) State <= 8'd155;
            end    
            
            //A7
            8'd155 : begin
                  SCL <= 1'b0;
                  SDA <= D[7];             
                  State <= State + 1'b1; 
            end                 
                  
            8'd156 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd157 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd158 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 6
            8'd159 : begin
                  SCL <= 1'b0;
                  SDA <= D[6];  
                  State <= State + 1'b1;               
            end   

            8'd160 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd161 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd162 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 5
            8'd163 : begin
                  SCL <= 1'b0;
                  SDA <= D[5]; 
                  State <= State + 1'b1;                
            end   

            8'd164 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd165 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd166 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 4
            8'd167 : begin
                  SCL <= 1'b0;
                  SDA <= D[4]; 
                  State <= State + 1'b1;                
            end   

            8'd168 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd169 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd170 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 3
            8'd171 : begin
                  SCL <= 1'b0;
                  SDA <= D[3]; 
                  State <= State + 1'b1;                
            end   

            8'd172 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd173 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd174 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            // transmit bit 2
            8'd175 : begin
                  SCL <= 1'b0;
                  SDA <= D[2]; 
                  State <= State + 1'b1;                
            end   

            8'd176 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd177 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd178 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
 
            // transmit bit 1
            8'd179 : begin
                  SCL <= 1'b0;
                  SDA <= D[1];  
                  State <= State + 1'b1;               
            end   

            8'd180 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd181 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd182 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end
            
            // transmit bit 0
            8'd183 : begin
                  SCL <= 1'b0;
                  SDA <= D[0];     
                  State <= State + 1'b1;           
            end   

            8'd184 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd185 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd186 : begin
                  SCL <= 1'b0;                  
                  State <= State + 1'b1;
            end
            
            // read the ACK bit from the sensor and display it on LED[7]
            8'd187 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd188 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd189 : begin
                  SCL <= 1'b1;
                  SACK_bit <= SDA;                 
                  State <= State + 1'b1;
            end   
            

            8'd190 : begin
                  SCL <= 1'b0;
                  if (SingleByteData == 8'b00110010) RW <= 2'd1;
                  else if (SingleByteData == 8'b00111100) mRW <= 2'd1;
                  State <= 8'd204;
            end 
            
            //repeat
            8'd75 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b1;
                  State <= State + 1'b1;                                
            end
            
            8'd76 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b1;
                  State <= State + 1'b1;                                
            end
            
            8'd77 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b0;
                  State <= State + 1'b1;                                
            end   
            
            8'd78 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;
                  State <= 8'd80;                 
            end   
                                                                                        
            //SingleByteData2
            8'd80 : begin
                  SDA <= SingleByteData2[7];             
                  State <= State + 1'b1; 
            end                 
                  
            8'd81 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd82 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd83 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 6
            8'd84 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[6];  
                  State <= State + 1'b1;               
            end   

            8'd85 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd86 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd87 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 5
            8'd88 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[5]; 
                  State <= State + 1'b1;                
            end   

            8'd89 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd90 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd91 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 4
            8'd92 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[4]; 
                  State <= State + 1'b1;                
            end   

            8'd93 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd94 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd95 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   

            // transmit bit 3
            8'd96 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[3]; 
                  State <= State + 1'b1;                
            end   

            8'd97 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd98 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd99 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            // transmit bit 2
            8'd100 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[2]; 
                  State <= State + 1'b1;                
            end   

            8'd101 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd102 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd103 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
 
            // transmit bit 1
            8'd104 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[1];  
                  State <= State + 1'b1;               
            end   

            8'd105 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd106 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd107 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end
            
            // transmit bit 0
            8'd108 : begin
                  SCL <= 1'b0;
                  SDA <= SingleByteData2[0];      
                  State <= State + 1'b1;           
            end   

            8'd109 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd110 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd111 : begin
                  SCL <= 1'b0;                  
                  State <= State + 1'b1;
            end  
                        
            // read the ACK bit from the sensor and display it on LED[7]
            8'd112 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd113 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd114 : begin
                  SCL <= 1'b1;
                  SACK_bit <= SDA;                 
                  State <= State + 1'b1;
            end   
            

            8'd115 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end                       
            
            //MSB LSB
            8'd116 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd117 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd118 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[7] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[15] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[7] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[15] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[7] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[15] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[7] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[15] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[7] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[15] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[7] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[15] <= SDA;             
                  State <= State + 1'b1;
            end   
            
            8'd119 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end       
            
            //6
            8'd120 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd121 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd122 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[6] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[14] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[6] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[14] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[6] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[14] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[6] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[14] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[6] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[14] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[6] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[14] <= SDA;                    
                  State <= State + 1'b1;
            end   
            
            8'd123 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end   
            
            //5
            8'd124 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd125 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd126 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[5] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[13] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[5] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[13] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[5] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[13] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[5] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[13] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[5] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[13] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[5] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[13] <= SDA;                    
                  State <= State + 1'b1;
            end   
            
            8'd127 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end    
            
            //4
            8'd128 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd129 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd130 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[4] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[12] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[4] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[12] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[4] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[12] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[4] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[12] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[4] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[12] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[4] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[12] <= SDA;                 
                  State <= State + 1'b1;
            end   
            
            8'd131 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end      
            
            //3
            8'd132 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd133 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd134 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[3] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[11] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[3] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[11] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[3] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[11] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[3] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[11] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[3] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[11] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[3] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[11] <= SDA;                     
                  State <= State + 1'b1;
            end   
            
            8'd135 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end 
            
            //2
            8'd136 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd137 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd138 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[2] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[10] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[2] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[10] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[2] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[10] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[2] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[10] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[2] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[10] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[2] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[10] <= SDA;                  
                  State <= State + 1'b1;
            end   
            
            8'd139 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end 
            
            //1
            8'd140 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd141 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd142 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[1] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[9] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[1] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[9] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[1] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[9] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[1] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[9] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[1] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[9] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[1] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[9] <= SDA;                      
                  State <= State + 1'b1;
            end   
            
            8'd143 : begin
                  SCL <= 1'b0;
                  State <= State + 1'b1;
            end  
            
            //0
            8'd144 : begin
                  SCL <= 1'b0;
                  SDA <= 1'bz;
                  State <= State + 1'b1;                 
            end   

            8'd145 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end            
            
            8'd146 : begin
                  SCL <= 1'b1;
                  if (flag == 0 && SingleByteData == 8'b00110010) XHA[0] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00110010) XHA[8] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00110010) YHA[0] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00110010) YHA[8] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00110010) ZHA[0] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00110010) ZHA[8] <= SDA;    
                  else if (flag == 0 && SingleByteData == 8'b00111100) mXHA[0] <= SDA;
                  else if (flag == 1 && SingleByteData == 8'b00111100) mXHA[8] <= SDA;
                  else if (flag == 2 && SingleByteData == 8'b00111100) mYHA[0] <= SDA;
                  else if (flag == 3 && SingleByteData == 8'b00111100) mYHA[8] <= SDA;
                  else if (flag == 4 && SingleByteData == 8'b00111100) mZHA[0] <= SDA;
                  else if (flag == 5 && SingleByteData == 8'b00111100) mZHA[8] <= SDA;                     
                  State <= State + 1'b1;
            end   
            
            8'd147 : begin
                  SCL <= 1'b0;
                  if (flag == 5) State <= State + 1'b1;
                  else State <= 8'd200;
            end                                                                                       
            
            8'd148 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b1;      
                  State <= State + 1'b1;           
            end   

            8'd149 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd150 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd151 : begin
                  SCL <= 1'b0;                  
                  State <= 8'd204;
            end
            
            
            
            // write the ACK bit to the sensor and display it on LED[7]
            8'd200  : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;     
                  State <= State + 1'b1;           
            end   

            8'd201 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd202 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   

            8'd203 : begin
                  SCL <= 1'b0;
                  State <= 8'd116;
                  flag <= flag + 1'b1;                 
            end
               
            //stop bit sequence and go back to STATE_INIT            
            8'd204 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;             
                  State <= State + 1'b1;
            end   

            8'd205 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b0;
                  State <= State + 1'b1;
            end                                    

            8'd206 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b1;
                  flag <= 5'd0;
                  if(RW == 2'd1 && SingleByteData == 8'b00110010) begin
                    SingleByteData <= 8'b00111100;
                    SingleByteData2 <= 8'b00111101;
                    A_W <= 8'b00000010;
                    A_R <= 8'b10000011;
                    D <= 8'b00000000;
                  end
                  else if(mRW == 2'd1 && SingleByteData == 8'b00111100) begin
                    SingleByteData <= 8'b00110010;
                    SingleByteData2 <= 8'b00110011;
                    A_W <= 8'b00100000;
                    D <= 8'b10010111;
                    A_R = 8'b10101000;
                  end
                  State <= STATE_INIT;                
            end              
            
            //If the FSM ends up in this state, there was an error in teh FSM code
            //LED[6] will be turned on (signal is active low) in that case.
            default : begin
                  error_bit <= 0;
            end                              
        endcase                           
    end
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(XHA));
    
                        
    okWireOut wire21 (  .okHE(okHE), 
                        .okEH(okEHx[ 1*65 +: 65 ]),
                        .ep_addr(8'h21), 
                        .ep_datain(YHA));
                      
                        
    okWireOut wire22 (  .okHE(okHE), 
                        .okEH(okEHx[ 2*65 +: 65 ]),
                        .ep_addr(8'h22), 
                        .ep_datain(ZHA));
    
    okWireOut wire23 (  .okHE(okHE), 
                        .okEH(okEHx[ 3*65 +: 65 ]),
                        .ep_addr(8'h23), 
                        .ep_datain(mXHA));
    
                        
    okWireOut wire24 (  .okHE(okHE), 
                        .okEH(okEHx[ 4*65 +: 65 ]),
                        .ep_addr(8'h24), 
                        .ep_datain(mYHA));
                      
                        
    okWireOut wire25 (  .okHE(okHE), 
                        .okEH(okEHx[ 5*65 +: 65 ]),
                        .ep_addr(8'h25), 
                        .ep_datain(mZHA));                                      
                        

                                                                                                   
                        
                        
//motor      
    okWireIn wire15 (   .okHE(okHE), 
                        .ep_addr(8'h05), 
                        .ep_dataout(direction));          
                        
    okWireIn wire16 (   .okHE(okHE), 
                        .ep_addr(8'h06), 
                        .ep_dataout(num_pulses));  
                        
    okWireIn wire17 (   .okHE(okHE), 
                        .ep_addr(8'h07), 
                        .ep_dataout(enable));  
                                                                                        
                                                              
endmodule
