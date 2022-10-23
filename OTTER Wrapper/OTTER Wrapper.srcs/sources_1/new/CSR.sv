`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2022 06:08:24 PM
// Design Name: 
// Module Name: CSR
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


module CSR(
    input RST, INT_TAKEN, WR_EN, CLK,
    input [11:0] ADDR,
    input [31:0] PC, WD,
    output logic CSR_MIE,
    output logic [31:0] CSR_MEPC, CSR_MTVEC, RD
    );
    
    always_ff @ (posedge CLK) begin
        if (RST == 1'b1) begin                  //reset all registers to zero
            CSR_MEPC <= 0; 
            CSR_MTVEC <= 0; 
            CSR_MIE <= 0;
        end else if (INT_TAKEN == 1'b1) begin   //interrupt state
            CSR_MIE <= 0; 
            CSR_MEPC <= PC;
        end else if (WR_EN == 1'b1) begin   //synchronous write (used by csrrw)
            case (ADDR) 
                12'h304 : CSR_MIE <= WD[0];
                12'h305 : CSR_MTVEC <= WD;
                12'h341 : CSR_MEPC <= WD;
            endcase
        end
    end
    
    always_comb begin       //asynchronous read
        RD = 0;
        case (ADDR)     //RD value is based on the ADDR input
            12'h304 : RD = {31'd0, CSR_MIE};
            12'h305 : RD = CSR_MTVEC;
            12'h341 : RD = CSR_MEPC;
        endcase
    end
endmodule
