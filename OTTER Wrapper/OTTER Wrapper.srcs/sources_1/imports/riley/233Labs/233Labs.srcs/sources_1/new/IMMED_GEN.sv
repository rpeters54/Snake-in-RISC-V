`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2022 04:42:14 PM
// Design Name: 
// Module Name: IMMED_GEN
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
/*
Uses concatenation to generate immediates
{#{value}} means that value is duplicated # times in the output 
*/
module IMMED_GEN(
    input [31:7] IR,
    output logic [31:0] U, I, S, B, J
    );
    
    always_comb begin               
        U = {IR[31:12], 12'd0};
        I = {{21{IR[31]}}, IR[30:20]};
        S = {{21{IR[31]}}, IR[30:25], IR[11:7]};
        B = {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'd0};
        J = {{12{IR[31]}}, IR[19:12], IR[20], IR[30:21], 1'd0};
    end
endmodule
