`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2022 03:18:16 PM
// Design Name: 
// Module Name: CU_FSM
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


module CU_FSM(
    input RST, CLK, INTR,
    input [6:0] OPCODE,
    input [14:12] FUNC,
    output logic PCWrite, regWrite, memWE2, memRDEN1, 
        memRDEN2, reset, csr_WE, int_taken
    );
    
    typedef enum {INIT, FETCH, EXEC, WR_BK, INTRPT} STATE;
    STATE PS = INIT;
    STATE NS;
    
    always_ff @ (posedge CLK) begin
        if (RST == 1'b1) 
            PS <= INIT;
        else
            PS <= NS;
    end
    
    always_comb begin
       PCWrite = 0; regWrite = 0; memWE2 = 0; 
       memRDEN1 = 0; memRDEN2 = 0; reset = 0;
       csr_WE = 0; int_taken = 0;
       case (PS)
        INIT : begin
            reset = 1'b1;
            NS = FETCH;
        end
        FETCH : begin
            memRDEN1 = 1'b1;
            NS = EXEC;
        end
        EXEC :  begin
            if (INTR == 1'b1) NS = INTRPT;
            else NS = FETCH;
            case(OPCODE) 
                7'b0110011 : begin  //R-Type OPCODE
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b0010011 : begin  //I-Type OPCODE *logical instructions
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b1100111 : begin  //I-Type OPCODE *jalr
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b0000011 : begin  //I-Type OPCODE *load instructions
                   memRDEN2 = 1'b1;
                   NS = WR_BK;
                end
                7'b0100011 : begin  //S-Type OPCODE *store instructions
                   memWE2 = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b1100011 : begin  //B-Type OPCODE;
                   PCWrite = 1'b1;
                end
                7'b0110111 : begin  //lui OPCODE
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b0010111 : begin  //auipc OPCODE
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b1101111 : begin  //J-Type OPCODE *jal
                   regWrite = 1'b1;
                   PCWrite = 1'b1;
                end
                7'b1110011 : begin //INTR OPCODE
                    PCWrite = 1'b1;             //true for mret and csrrw
                    if (FUNC[12] == 1'b1) begin  //only true for csrrw
                        csr_WE = 1'b1;
                        regWrite = 1'b1;
                    end
                end
            endcase 
        end
        WR_BK : begin           //special case for load instructions
            regWrite = 1'b1;    //memory reads require an extra clock cycle
            PCWrite = 1'b1;
            if (INTR == 1'b1) NS = INTRPT;
            else NS = FETCH;
        end
        INTRPT : begin          //interrupt routine
            int_taken = 1'b1;   //output signal sent to CSR and DCDR
            PCWrite = 1'b1;
            NS = FETCH;
        end
        default: NS = INIT;
       endcase 
    end
endmodule
