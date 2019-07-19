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
input clk_in,//25M
input clk100,
input rst,
input[31:0]idata,
input cs,
output hsync,
output vsync,
output [3:0]vga_r,
output [3:0]vga_g,
output [3:0]vga_b
    );

wire clk=clk_in;
wire [31:0] xpos;
wire [31:0] ypos;

wire[8:0]block;
wire[4:0]x_last5=xpos[4:0];
wire[4:0]y_last5=ypos[4:0];

// wire[4:0]x_base=xpos>>5;
// wire[4:0]y_base=ypos>>5;

// wire[4:0]x_base=xpos[9:5];
// wire[4:0]y_base=ypos[9:5];

wire[8:0]x_base={3'b000,xpos[10:5]};
wire[8:0]y_base={3'b000,ypos[10:5]};

//assign block=y_base<<4 + 4 + x_base+1;//from 1 - 150   
//assign block=y_base<<4 + x_base+ 5;
assign block=y_base*9'd20 + x_base;

reg[5:0]content[299:0];//in total 300 block

integer i;
always @(posedge clk100 or posedge rst)
    if(rst)begin
        for(i=0;i<300;i=i+1)
            content[i]<=0;
    end
    else if(cs)begin
         content[idata[16:8]]<=idata[5:0];
     end

        
wire[31:0]Men_data;
wire[10:0]addr_last5={6'b000000,y_last5};
wire[10:0]content_block={5'b00000,content[block]};
wire[10:0]addr=(content_block<<5)+addr_last5;
dist_mem_gen_0 vga_const (
  .a(addr),      // input wire [10 : 0] a
  .spo(Men_data)  // output wire [31 : 0] spo
);

wire data=Men_data[31-x_last5];

reg[11:0]color[299:0];        
integer j;
always @(posedge clk100 or posedge rst)
    if(rst)begin
        for(j=0;j<300;j=j+1)
            color[j]<=0;
    end
    else if(cs) begin
        color[idata[16:8]]<=idata[31:20];
    end

    
wire vga_valid;
    
VGA_640x480 vga_6_4_inst(
.clk(clk),
.rst(rst),
.HS(hsync),
.VS(vsync),
.valid(vga_valid),
.xpos(xpos),
.ypos(ypos));


assign vga_r=data?color[block][11:8]:4'b0000;
assign vga_g=data?color[block][7:4]:4'b0000;
assign vga_b=data?color[block][3:0]:4'b0000;

// VGA_Color vc_inst(
// .clk(clk),
// .rst(rst),
// .valid(vga_valid),
// .data(show_data),
// .red(vga_r),
// .green(vga_g),
// .blue(vga_b));

endmodule
