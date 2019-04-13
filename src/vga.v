`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/04 23:27:20
// Design Name: 
// Module Name: vga
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


module vga(
input clk_in,//50M
input clk_in_25,
input rst_in,
input[31:0]i_data,
input we,
output hsync,
output vsync,
output [3:0]vga_r,
output [3:0]vga_g,
output [3:0]vga_b,
output intr,
output [31:0]o_data
    );
    
wire clk=clk_in_25;
wire rst=rst_in;

wire vga_valid;
wire[31:0]show_data;
wire restart;

reg[31:0]data2;

// data2
//cpu传来写信号 50M
always @(posedge clk_in or posedge rst) begin
  if (rst) begin
//    data2<=32'd0;
     data2 <=32'hffffffff;
  end
  else if (we) begin
    data2<=i_data;//CPU写入I/O
  end
  else begin
    data2<=data2;
  end
end

assign o_data={{31{1'b0}},restart};
    
VGA_640x480 vga_6_4_inst(
.clk(clk),
.rst(rst),
.data2(data2),
.HS(hsync),
.VS(vsync),
.valid(vga_valid),
.o_data(show_data),
.intr(intr),
.rstart(restart));






VGA_Color vc_inst(
.clk(clk),
.rst(rst),
.valid(vga_valid),
.data(show_data),
.red(vga_r),
.green(vga_g),
.blue(vga_b));

endmodule
