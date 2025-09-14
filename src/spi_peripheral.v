`default_nettype none   

module spi_peripheral (
//inputs
    input wire clk,
    input wire rst_n,
    input wire COPI,
    input wire SCLK,
    input wire nCS,
//outputs
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

//synchronizing regs
reg [1:0] SCLK_sync;
reg [1:0] nCS_sync;
reg [1:0] COPI_sync;

reg [15:0] serialData;
reg [4:0] clkCount;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
        SCLK_sync <= 2'b00;
        nCS_sync <= 2'b11;  //nCS is 1 at idle
        COPI_sync <= 2'b00;


        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <= 8'b0;
        en_reg_pwm_15_8 <= 8'b0;
        pwm_duty_cycle <= 8'b0;

        serialData <= 16'b0;
        clkCount <= 5'b0;

    end

    else begin
        
        //synchonizing to avoid metastability
        SCLK_sync <= {SCLK_sync[0], SCLK};
        nCS_sync <= {nCS_sync[0], nCS};
        COPI_sync <= {COPI_sync[0], COPI};

        // nCS falling edge
        if(!nCS_sync[0] & nCS_sync[1]) begin
            serialData <= 16'b0;
            clkCount <= 5'b0;
        end

        //reading on sclk rising edge, nCS held low
        else if ((!nCS_sync[1]) && (SCLK_sync[0] & !SCLK_sync[1])) begin
            if (clkCount < 5'd16) begin
                serialData <= {serialData[14:0], COPI_sync[1]};
                clkCount <= clkCount + 1'b1;
            end
        end
         

        //at 16th tick, nCS rising edge and assuming first bit is write:
        if ((clkCount == 5'd16) && (nCS_sync[0] & !nCS_sync[1]) && serialData[15]) begin //only corresponding to write input
            case (serialData[14:8])
                7'h00 : 
                    en_reg_out_7_0 <= serialData[7:0];
                7'h01 : 
                    en_reg_out_15_8 <= serialData[7:0];
                7'h02 : 
                    en_reg_pwm_7_0 <= serialData[7:0];
                7'h03 : 
                    en_reg_pwm_15_8 <= serialData[7:0];
                7'h04 : 
                    pwm_duty_cycle <= serialData[7:0];
                default: ;
            endcase
        end
    end
end



endmodule