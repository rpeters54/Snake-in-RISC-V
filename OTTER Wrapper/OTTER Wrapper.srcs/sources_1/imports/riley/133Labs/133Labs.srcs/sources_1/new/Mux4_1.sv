`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2021 01:24:48 PM
// Design Name: 
// Module Name: Mux4_1
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


module Mux4_1 # (parameter WIDTH = 4)(
    input [WIDTH-1:0] ZERO, ONE, TWO, THREE,
    input [1:0] SEL,
    output logic [WIDTH-1:0] MUX_OUT
    );
    
    always_comb
    begin
        case (SEL)
            0: MUX_OUT = ZERO;
            1: MUX_OUT = ONE;
            2: MUX_OUT = TWO;
            3: MUX_OUT = THREE;
            default: MUX_OUT = 0;
        endcase
    end
endmodule
