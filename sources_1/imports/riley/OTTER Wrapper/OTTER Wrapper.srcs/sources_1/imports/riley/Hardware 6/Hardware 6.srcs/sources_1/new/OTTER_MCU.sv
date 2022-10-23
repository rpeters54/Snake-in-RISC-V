`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2022 08:07:08 PM
// Design Name: 
// Module Name: OTTER_MCU
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
  OTTERMCU CPU (.CPU_RST(s_reset), .CPU_INTR(1'b0), .CPU_CLK(clk_50),
                  .CPU_IOBUS_OUT(IOBUS_out), .CPU_IOBUS_IN(IOBUS_in),
                  .CPU_IOBUS_ADDR(IOBUS_addr), .CPU_IOBUS_WR(IOBUS_wr));
*/
module OTTERMCU(
    input [31:0] CPU_IOBUS_IN,
    input CPU_RST, CPU_INTR, CPU_CLK,
    output logic [31:0] CPU_IOBUS_OUT, CPU_IOBUS_ADDR,
    output logic CPU_IOBUS_WR
    );
    
    //Connections between 32-bit inputs and outputs
    logic [31:0] ir, DATA_OUT, RF_WD_BRIDGE, ALU_Abridge, ALU_Bbridge, ALU_OUT, 
        RS1_OUT, RS2_OUT, U_OUT, I_OUT, S_OUT, B_OUT, J_OUT, JALR_bridge, 
        BRANCH_bridge, JAL_bridge, PC_OUT, NEXT_ADDR;
    
    //all CU_DCDR logical signals
    logic EQUAL, LESS, LESS_UN, ALU_srcA;
    logic [1:0] ALU_srcB, RF_WR_SEL;
    logic [2:0] PC_SOURCE;
    logic [3:0] ALU_FUN;
    
    //all CU_FSM logical signals
    logic PCWrite, regWrite, memWE2, memRDEN1, memRDEN2, 
        reset, csr_WE, int_taken;
        
    //all CSR logical signals
    logic csr_mie;
    logic [31:0] csr_mtvec, csr_mepc, csr_rd;
    
    //defines two values for the top-level module
    assign CPU_IOBUS_ADDR = ALU_OUT;
    assign CPU_IOBUS_OUT = RS2_OUT;
    
    //Program Counter: keeps track of the current instruction
    PC pc (.JALR(JALR_bridge), .BRANCH(BRANCH_bridge), .JAL(JAL_bridge), .MTVEC(csr_mtvec), 
        .MEPC(csr_mepc), .PC_SOURCE(PC_SOURCE), .PC_WRITE(PCWrite), .PC_RST(reset), .CLK(CPU_CLK), 
        .PC_ADDRESS(PC_OUT), .INC(NEXT_ADDR));
    
    //Memory: stores all relevant data and instructions for the program
    Memory mem (.MEM_CLK(CPU_CLK), .MEM_RDEN1(memRDEN1), .MEM_RDEN2(memRDEN2),
        .MEM_WE2(memWE2), .MEM_ADDR1(PC_OUT[15:2]), .MEM_ADDR2(ALU_OUT),.MEM_DIN2(RS2_OUT), 
        .MEM_SIZE(ir[13:12]), .MEM_SIGN(ir[14]), .IO_IN(CPU_IOBUS_IN), .IO_WR(CPU_IOBUS_WR),
        .MEM_DOUT1(ir) , .MEM_DOUT2(DATA_OUT));
    
    //REG_FILE w/ Input MUX: contains all registers needed for the program
    Mux4_1 #(32) reg_mux (.ZERO(NEXT_ADDR), .ONE(csr_rd), .TWO(DATA_OUT), .THREE(ALU_OUT), 
        .SEL(RF_WR_SEL), .MUX_OUT(RF_WD_BRIDGE));
    REG_FILE rf (.RF_ADR1(ir[19:15]), .RF_ADR2(ir[24:20]), .RF_WA(ir[11:7]), 
        .RF_WD(RF_WD_BRIDGE), .RF_EN(regWrite), .CLK(CPU_CLK), .RF_RS1(RS1_OUT), .RF_RS2(RS2_OUT));

    //Immediate Generator: creates all types of immediates needed for different instructions
    IMMED_GEN imd (.IR(ir[31:7]), .U(U_OUT), .I(I_OUT), .S(S_OUT), .B(B_OUT), .J(J_OUT));
    
    //ALU w/ Input MUXES: location of all logical and arithmetic operations
    MUX2_1 #(32) amux (.ZERO(RS1_OUT), .ONE(U_OUT), .SEL(ALU_srcA), .F(ALU_Abridge));
    Mux4_1 #(32) bmux (.ZERO(RS2_OUT), .ONE(I_OUT), .TWO(S_OUT), .THREE(PC_OUT), 
        .SEL(ALU_srcB), .MUX_OUT(ALU_Bbridge));
    ALU alu (.A(ALU_Abridge), .B(ALU_Bbridge), .ALU_FUN(ALU_FUN), .RESULT(ALU_OUT));
    
    //Branch Address Generator: generates addresses for use in branch and jump instrucitions
    BRANCH_ADDR_GEN bag (.rs1(RS1_OUT), .I(I_OUT), .B(B_OUT), .J(J_OUT), .PC(PC_OUT), 
        .jal(JAL_bridge), .branch(BRANCH_bridge), .jalr(JALR_bridge));
    
    //Branch Condition Generator: verifies conditions of rs1 and rs2 for use in branch instructions
    BRANCH_COND_GEN bcg (.rs1(RS1_OUT), .rs2(RS2_OUT), .br_eq(EQUAL), .br_lt(LESS), .br_ltu(LESS_UN));
    
    //Control Unit Decoder: controls all mux selectors based on the instruction opcode and function number
    CU_DCDR decode (.OPCODE(ir[6:0]), .FUNC(ir[14:12]), .IR_30(ir[30]), .BR_EQ(EQUAL), 
        .BR_LT(LESS), .BR_LTU(LESS_UN), .ALU_FUN(ALU_FUN), .ALU_srcA(ALU_srcA),
        .ALU_srcB(ALU_srcB), .PC_SOURCE(PC_SOURCE), .RF_WR_SEL(RF_WR_SEL), .INT_TAKEN(int_taken));
    
    assign intr = CPU_INTR & csr_mie; 
    
    //Control Unit FSM: controls enable signals throughout the OTTER based on current state
    CU_FSM fsm (.RST(CPU_RST), .INTR(intr), .CLK(CPU_CLK), .OPCODE(ir[6:0]), .FUNC(ir[14:12]), 
        .PCWrite(PCWrite), .regWrite(regWrite), .memWE2(memWE2), .memRDEN1(memRDEN1), 
        .memRDEN2(memRDEN2), .reset(reset), .csr_WE(csr_WE), .int_taken(int_taken));
    
    //Control State Registers: handles interrupt state data and triggering
    CSR csr (.RST(reset), .INT_TAKEN(int_taken), .WR_EN(csr_WE), .CLK(CPU_CLK), .ADDR(ir[31:20]),
        .PC(PC_OUT), .WD(RS1_OUT), .CSR_MIE(csr_mie), .CSR_MEPC(csr_mepc), .CSR_MTVEC(csr_mtvec),
        .RD(csr_rd));
    
endmodule
