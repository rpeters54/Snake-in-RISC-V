`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: J. Calllenes
//           P. Hummel
// 
// Create Date: 01/20/2019 10:36:50 AM
// Design Name: 
// Module Name: OTTER_Wrapper 
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

module OTTER_Wrapper(
   input CLK,
   input BTNL,
   input BTNC,
   input BTNR,
   input BTNU,
   input BTND,
   input [15:0] SWITCHES,
   output logic [15:0] LEDS,
   output [7:0] CATHODES,
   output [3:0] ANODES,
   output [7:0] VGA_RGB,
   output VGA_HS,
   output VGA_VS
   );
        
    // INPUT PORT IDS ////////////////////////////////////////////////////////
    // Right now, the only possible inputs are the switches
    // In future labs you can add more MMIO, and you'll have
    // to add constants here for the mux below
    localparam SWITCHES_AD = 32'h11000000;
    localparam RANDOM_AD = 32'h11000060;
    localparam BUTTONS_AD = 32'h11000100;
    localparam VGA_READ_AD = 32'h11000160;
           
    // OUTPUT PORT IDS ///////////////////////////////////////////////////////
    // In future labs you can add more MMIO
    localparam LEDS_AD      = 32'h11000020;
    localparam SSEG_AD     = 32'h11000040;
    localparam VGA_ADDR_AD = 32'h11000120;
    localparam VGA_COLOR_AD = 32'h11000140; 
    
   // Signals for connecting OTTER_MCU to OTTER_wrapper /////////////////////////
   logic s_reset, s_interrupt;
   logic sclk = 1'b0;   
   logic [31:0] IOBUS_out,IOBUS_in,IOBUS_addr;
   logic IOBUS_wr;
   
   // Signals for connecting VGA Framebuffer Driver
   logic r_vga_we;             // write enable
   logic [12:0] r_vga_wa;      // address of framebuffer to read and write
   logic [7:0] r_vga_wd;       // pixel color data to write to framebuffer
   logic [7:0] r_vga_rd;       // pixel color data read from framebuffer
 
   logic [15:0]  r_SSEG;
   
   // Connect Signals ////////////////////////////////////////////////////////////
   assign s_interrupt = btn_int;
   assign s_reset = BTND;
   
   // Declare OTTER_CPU ///////////////////////////////////////////////////////
   OTTERMCU MCU (.CPU_RST(s_reset),.CPU_INTR(s_interrupt), .CPU_CLK(sclk),  
                   .CPU_IOBUS_OUT(IOBUS_out),.CPU_IOBUS_IN(IOBUS_in),
                   .CPU_IOBUS_ADDR(IOBUS_addr),.CPU_IOBUS_WR(IOBUS_wr));

   // Declare Seven Segment Display /////////////////////////////////////////
   SevSegDisp SSG_DISP (.DATA_IN(r_SSEG), .CLK(CLK), .MODE(1'b0),
                       .CATHODES(CATHODES), .ANODES(ANODES));
   
   // Map Button Inputs and Interrupt Logic /////////////////////////////////
   assign btn_int = (BTNL | BTNR | BTNC | BTNU);    //wires interrupt to 4 buttons
   logic [1:0] button_pressed = 2'd0;
   
   
   always_ff @ (posedge sclk) begin         //directional button input
        if (BTNR == 1'b1)   
            button_pressed <= 2'd0;         // RIGHT = 0
        if (BTNL == 1'b1)
            button_pressed <= 2'd1;         // LEFT = 1
        if (BTNC == 1'b1)
            button_pressed <= 2'd2;         // DOWN = 2
        if (BTNU == 1'b1)
            button_pressed <= 2'd3;         // UP = 3
   end
   
   // Declare Pseudorandom Number Generator /////////////////////////////////
   logic [31:0] pseudoRand;
   RandGen rg (.CLK(CLK), .RST(1'b0), .RANDOM(pseudoRand));
   
   // Declare VGA Frame Buffer //////////////////////////////////////////////
   vga_fb_driver_80x60 VGA(.CLK_50MHz(sclk), .WA(r_vga_wa), .WD(r_vga_wd),
                               .WE(r_vga_we), .RD(r_vga_rd), .ROUT(VGA_RGB[7:5]),
                               .GOUT(VGA_RGB[4:2]), .BOUT(VGA_RGB[1:0]),
                               .HS(VGA_HS), .VS(VGA_VS));   
 
   // Clock Divider to create 50 MHz Clock /////////////////////////////////
   always_ff @(posedge CLK) begin
       sclk <= ~sclk;
   end

   // Connect Board peripherals (Memory Mapped IO devices) to IOBUS /////////////////////////////////////////
   always_ff @ (posedge sclk) begin
        r_vga_we<=0;       
        if(IOBUS_wr)
            case(IOBUS_addr)
                LEDS_AD: LEDS <= IOBUS_out[15:0];    
                SSEG_AD: r_SSEG <= IOBUS_out[15:0];
                VGA_ADDR_AD: r_vga_wa <= IOBUS_out[12:0];
                VGA_COLOR_AD: begin  
                        r_vga_wd <= IOBUS_out[7:0];
                        r_vga_we <= 1;  
                    end     
            endcase
    end
    
    always_comb begin
        case(IOBUS_addr)
            SWITCHES_AD: IOBUS_in = {16'b0, SWITCHES};
            RANDOM_AD:   IOBUS_in = pseudoRand;
            BUTTONS_AD:  IOBUS_in = {30'b0, button_pressed}; 
            VGA_READ_AD: IOBUS_in = {24'b0, r_vga_rd};
            default: IOBUS_in = 32'b0;
        endcase
    end
   endmodule

