`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2022 01:13:08 AM
// Design Name: 
// Module Name: BRANCH_COND_GEN
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


module BRANCH_COND_GEN(
    input [31:0] rs1, rs2,
    output logic br_eq, br_lt, br_ltu
    );
    
    always_comb begin    //checks is rs1 is equal to or less than rs2 (signed and unsigned)
    //br_eq = 0; br_lt = 0; br_ltu = 0;
    br_eq = rs1 == rs2;
    br_lt = $signed(rs1) < $signed(rs2);
    br_ltu = rs1 < rs2;
    /*
    if (rs1 == rs2) br_eq = 1'b1;                  //separate if statements because lt and ltu
    if ($signed(rs1) < $signed(rs2)) br_lt = 1'b1;     //can happen simultaneously
    if (rs1 < rs2) br_ltu = 1'b1;
    */
    end
endmodule
