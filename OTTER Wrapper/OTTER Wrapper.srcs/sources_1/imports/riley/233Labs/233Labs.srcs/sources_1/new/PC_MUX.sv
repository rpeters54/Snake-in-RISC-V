`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2022 02:27:31 PM
// Design Name: 
// Module Name: PC_MUX
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


module PC_MUX(
    input [31:0] INC, JALR, BRANCH, JAL, MTVEC, MEPC,
    input [2:0] PC_SOURCE,
    output logic [31:0] MUX_OUT
    );
    
    always_comb
    begin 
        case(PC_SOURCE)
            0 : MUX_OUT = INC;
            1 : MUX_OUT = JALR;
            2 : MUX_OUT = BRANCH;
            3 : MUX_OUT = JAL;
            4 : MUX_OUT = MTVEC;
            5 : MUX_OUT = MEPC;
            default : MUX_OUT = 32'hDEADDEAD;
        endcase
    end
endmodule
