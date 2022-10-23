`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2022 12:45:31 PM
// Design Name: 
// Module Name: ALU
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


module ALU(
    input [31:0] A, B,
    input [3:0] ALU_FUN,
    output logic [31:0] RESULT
    );
    
    always_comb begin
        case(ALU_FUN)   //case statement acts like a mux selecting between operations
            4'b0000 : RESULT = A + B;               //add
            4'b1000 : RESULT = A - B;               //sub
            4'b0110 : RESULT = A | B;               //or
            4'b0111 : RESULT = A & B;               //and
            4'b0100 : RESULT = A ^ B;               //xor
            4'b0101 : RESULT = A >> B[4:0];         //srl
            4'b0001 : RESULT = A << B[4:0];         //sll
            4'b1101 : RESULT = $signed(A) >>> B[4:0];        //sra
            4'b0010 : RESULT = $signed(A) < $signed(B);     //slt
            4'b0011 : RESULT = A < B;                       //sltu
           /* 4'b0010 : begin                         //slt
                if ($signed(A) < $signed(B)) begin  
                    RESULT = 32'd1;   //uses $signed to denote signed comparison
                end else begin
                    RESULT = 32'd0;
                end
            end
            4'b0011 : begin                         //sltu
                if (A < B) begin
                    RESULT = 32'd1;
                end else begin
                    RESULT = 32'd0;
                end
            end*/
            4'b1001 : RESULT = A;                   //lui_copy
            default : RESULT = 32'hDEADDEAD;        //default
        endcase
    end
endmodule
