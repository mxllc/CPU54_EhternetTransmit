`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:14:40 05/03/2017 
// Design Name: 
// Module Name:    io_sel 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module io_sel(
    input [31:0] addr,
	 input cs,
	 input sig_w,
	 input sig_r,
	 output dmem_cs,
	 output vga_cs
    );

// assign seg7_cs = (addr == 32'h10010000 && cs == 1 && sig_w == 1) ? 1 : 0;
// assign switch_cs = (addr == 32'h10010010 && cs == 1 && sig_r == 1) ? 1 : 0;
	assign vga_cs = ((addr == 32'h10810000 | addr == 32'h10810004)&& cs == 1) ? 1 : 0;
	assign dmem_cs = cs & (~vga_cs);
endmodule