`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University
// Engineer: Riley Peters 
// 
// Create Date: 10/12/2021 11:20:01 AM
// Design Name: 
// Module Name: MUX2_1
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


module MUX2_1 #(parameter WIDTH = 4)(
    input [WIDTH - 1:0] ZERO,
    input [WIDTH - 1:0] ONE,
    input SEL,
    output logic [WIDTH - 1:0] F
    );
    
    always_comb
    begin
        case(SEL)
        1'b1 : F = ONE;
        1'b0 : F = ZERO;
        endcase
    end
endmodule