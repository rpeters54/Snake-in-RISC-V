`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2022 05:43:44 PM
// Design Name: 
// Module Name: REG_FILE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module REG_FILE(
    input [4:0] RF_ADR1, RF_ADR2, RF_WA,
    input [31:0] RF_WD,
    input RF_EN, CLK,
    output logic [31:0] RF_RS1, RF_RS2
    );
    
    logic [31:0] register [0:31]; //32, 32-bit registers 
    
    initial begin   //register 0 is initially set to zero
        for(int i = 0; i < 32; i++) begin
            register[i] <= 32'd0;
        end
    end
    
    always_comb begin   //dual read functionality
        RF_RS1 = register[RF_ADR1]; //output register value given address
        RF_RS2 = register[RF_ADR2]; 
    end
    
    always_ff @ (posedge CLK) begin //single write functionality
        if (RF_EN && RF_WA != 0) begin //can not write to register 0
            register[RF_WA] <= RF_WD;
        end
    end
    
endmodule
