`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2022 02:27:31 PM
// Design Name: 
// Module Name: PC
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


module PC(
    input [31:0] JALR, BRANCH, JAL, MTVEC, MEPC,
    input [2:0] PC_SOURCE,
    input PC_WRITE, PC_RST, CLK,
    output logic [31:0] PC_ADDRESS, INC
    );
    
    logic [31:0] MUX_bridge;
    
    assign INC = PC_ADDRESS + 3'd4;
    
    PC_MUX pmux (.INC(INC), .JALR(JALR), .BRANCH(BRANCH), .JAL(JAL), .MTVEC(MTVEC), 
        .MEPC(MEPC), .PC_SOURCE(PC_SOURCE), .MUX_OUT(MUX_bridge));
    PC_Reg preg (.PC_WRITE(PC_WRITE), .PC_RST(PC_RST), .PC_DIN(MUX_bridge), 
        .CLK(CLK), .PC_ADDRESS(PC_ADDRESS));
    
endmodule
