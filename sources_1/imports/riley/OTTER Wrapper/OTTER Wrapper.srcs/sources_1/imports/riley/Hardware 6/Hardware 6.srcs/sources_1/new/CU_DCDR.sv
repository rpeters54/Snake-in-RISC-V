`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2022 03:54:39 PM
// Design Name: 
// Module Name: CU_DCDR
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


module CU_DCDR(
    input [6:0] OPCODE,
    input [14:12] FUNC,
    input IR_30, INT_TAKEN, BR_EQ, BR_LT, BR_LTU,
    output logic [3:0] ALU_FUN,
    output logic ALU_srcA,
    output logic [1:0] ALU_srcB,
    output logic [2:0] PC_SOURCE,
    output logic [1:0] RF_WR_SEL
    );
    
    logic comp;
    
    always_comb begin
        ALU_FUN = 0; ALU_srcA = 0; ALU_srcB = 0;
        PC_SOURCE = 0; RF_WR_SEL = 0; comp = 0;
        if (INT_TAKEN == 1'b1)  //Interrupt Case
            PC_SOURCE = 3'd4;
        else begin
            case(OPCODE)
                7'b0110011 : begin  //R-Type OPCODE
                    ALU_srcA = 0;   //arithmetic/logical operations including two registers
                    ALU_srcB = 0;
                    RF_WR_SEL = 2'd3;
                    PC_SOURCE = 0;
                    ALU_FUN = {IR_30, FUNC};    //ALU_FUN varies based on command
                end
                7'b0010011 : begin  //I-Type OPCODE *no loading
                    ALU_srcA = 0;   //arithmetic/logical operations including a register
                    ALU_srcB = 2'd1;    //and an immediate
                    RF_WR_SEL = 2'd3;
                    PC_SOURCE = 0;
                    ALU_FUN = {1'b0, FUNC};        //ALU_FUN varies based on command
                    if (FUNC == 3'b101)            //if-statement caused by immediate
                        ALU_FUN = {IR_30, FUNC};
                end
                7'b1100111 : begin  //I-Type OPCODE *jalr
                    PC_SOURCE = 2'd1;   //jumps and links to the value stored in rs1
                    RF_WR_SEL = 0;      //added to an I-Type immediate
                end
                7'b0000011 : begin  //I-Type OPCODE *load instructions
                    ALU_srcA = 0;   //All load instructions; writing from memory to registers
                    ALU_srcB = 2'd1;
                    ALU_FUN = 4'b0000;
                    RF_WR_SEL = 2'd2;
                    PC_SOURCE = 0;
                end
                7'b0100011 : begin  //S-Type OPCODE *store instructions
                    ALU_srcA = 0;   //All store instructions; writing from registers to memory
                    ALU_srcB = 2'd2;
                    ALU_FUN = 4'b0000;
                    PC_SOURCE = 0;
                end
                7'b1100011 : begin  //B-Type OPCODE
                    case(FUNC[14:13])
                        2'd0 : comp = BR_EQ;
                        2'd2 : comp = BR_LT;
                        2'd3 : comp = BR_LTU;
                    endcase
                    if (comp != FUNC[12])       //given instruction, output is based on condition
                        PC_SOURCE = 2'd2;
                end
                7'b0110111 : begin  //lui OPCODE
                    ALU_srcA = 1'd1;    //Extends a 20-bit immediate (extra 12-bits after)
                    ALU_FUN = 4'b1001;  //Value passes through ALU and is stored in a register
                    RF_WR_SEL = 2'd3;
                    PC_SOURCE = 0;
                end
                7'b0010111 : begin  //auipc OPCODE
                   ALU_srcA = 1'd1;     //Adds a U-type immediate to the program count
                   ALU_srcB = 2'd3;     //which is stored in a register
                   ALU_FUN = 4'b0000;
                   RF_WR_SEL = 2'd3;
                   PC_SOURCE = 0;
                end
                7'b1101111 : begin  //J-Type OPCODE *jal
                   PC_SOURCE = 2'd3;    //Jumps to a new location (updates PC value)
                   RF_WR_SEL = 0;       //stores current location + 4 in a register
                end
                7'b1110011 : begin //INTR OPCODE
                    if (FUNC[12] == 1'b1) begin      //csrrw
                        RF_WR_SEL = 2'd1;           
                        PC_SOURCE = 0;
                    end else begin                  //mret
                        PC_SOURCE = 3'd5;
                    end
                end
            endcase
        end
    end
endmodule
