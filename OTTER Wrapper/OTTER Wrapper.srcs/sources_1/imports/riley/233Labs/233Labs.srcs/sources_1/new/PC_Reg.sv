`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2022 02:27:31 PM
// Design Name: 
// Module Name: PC_Reg
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


module PC_Reg(
    input PC_WRITE,
    input PC_RST,
    input [31:0] PC_DIN,
    input CLK,
    output logic [31:0] PC_ADDRESS = 0
    );
    
    always_ff @ (posedge CLK)
    begin
        if (PC_RST) PC_ADDRESS <= 0;
        else if (PC_WRITE) PC_ADDRESS <= PC_DIN;
    end
endmodule
