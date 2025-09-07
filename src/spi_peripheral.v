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
reg [3:0] clkCount;

//k change of plans
//process flags
reg dataRead = 1'b1;
reg dataReady = 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin //reset at active low

        SCLK_sync <= 2'b00;
        nCS_sync <= 2'b11;
        COPI_sync <= 2'b00;

        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <= 8'b0;
        en_reg_pwm_15_8 <= 8'b0;
        pwm_duty_cycle <= 8'b0;

        serialData <= 16'b0;
        clkCount <= 5'b0;

        dataReading = 1'b1;
        dataReady = 1'b0;
    end 
    
    else begin

        //synchonizing to avoid metastability
        SCLK_sync <= {SCLK_sync[0], SCLK};
        nCS_sync <= {nCS_sync[0], nCS};
        COPI_sync <= {COPI_sync[0], COPI};
        
        //active low nCS, receiving serial data

        if (nCS_sync[1] & !nCS_sync[0] & dataRead) begin 
            dataReading = 1'b0;
            dataReady = 1'b1;
        end 
        // if (nCS_sync[1] & !nCS_sync[0]) begin 
        //     serialData <= 16'b0; 
        //     clkCount <= 5'b0;
        // end 
        else if (!nCS_sync[1] & nCS_sync[0] & !dataReady & (clkCount == 4'd15)) begin 
            dataRead = 1'b1;
            dataReady = 1'b0;
            clkCount <= 4'b0;
            serialData <= 16'b0;
        end
        
        if (dataReady) begin
            if(SCLK_sync[1] & !SCLK_sync[0]) begin
                serialData <= {serialData[14:0], COPI_sync[1]};
                clkCount <= clkCount + 1'b1;
            end 
        end

        else if (dataRead & serialData[15]) begin  //+checking write_only bit in a go ~!
            case (serialData[14:8]) //address casing
                7'h00: begin 
                    en_reg_out_7_0 <= serialData[7:0]; 
                end
                7'h01: begin 
                    en_reg_out_15_8 <= serialData[7:0];
                end
                7'h02: begin 
                    en_reg_pwm_7_0 <= serialData[7:0];
                end
                7'h03: begin 
                    en_reg_pwm_15_8 <= serialData[7:0];
                end
                7'h04: begin 
                    pwm_duty_cycle <= serialData[7:0];
                end
                default: 
                ;
            endcase

            clkCount <= 5'b0;
            serialData <= 16'b0;
        end
    end
end 

endmodule