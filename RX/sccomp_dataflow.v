`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/04/21 20:52:06
// Design Name: 
// Module Name: Dataflow
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


module sccomp_dataflow(
input clk_in,
input reset,
output hsync,
output vsync,
output [3:0]vga_r,
output [3:0]vga_g,
output [3:0]vga_b,

inout MDIO,
output MDC,
output RESET,
inout RXD0,
inout RXD1,
inout RXERR,
output TXD0,
output TXD1,
output TXEN,
inout CRS_DV,
inout REF_CLKO,
output CLKIN



,
output [7:0] o_seg,
output [7:0] o_sel
    );
wire locked;
wire exc;
wire [31:0]status;
   
wire [31:0]rdata;
wire [31:0]wdata;
wire IM_R,DM_CS,DM_R,DM_W;
wire [31:0]inst,pc,addr;
wire inta,intr;
wire clk;
wire [31:0]data_fmem;
// wire [31:0]data_fvga;
wire rst=reset|~locked;
wire [31:0]ip_in;
wire seg7_cs,switch_cs;
wire[31:0]eth_data;

assign ip_in = pc-32'h00400000;

wire dmem_cs;
wire vga_cs;
wire enet_cs;
wire clk_vga;

clk_wiz_0 clk_inst
   (
    // Clock out ports
    .clk_out1(clk),     // output clk_out1
    .clk_out2(clk_vga),     // output clk_out2
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_in)); 

//clk_div #(3)cpu_clk(clk_in,clk);

/*地址译码*/
// io_sel io_mem(addr, DM_CS, DM_W, DM_R, seg7_cs, switch_cs);
io_sel io_mem(
   .addr(addr),
   .cs(DM_CS),
   .sig_w(DM_W),
   .sig_r(DM_R),
   .dmem_cs(dmem_cs),
   .vga_cs(vga_cs),
   .enet_cs(enet_cs)
    );

CPU54 sccpu(clk,rst,inst,rdata,pc,addr,wdata,IM_R,DM_CS,DM_R,DM_W,intr,inta);
//rdata 从dmem中读取来的数据


wire ether_ack;
reg temp_intr;
assign intr=temp_intr;
always @(posedge clk_in or posedge rst) begin
  if (rst) begin
    temp_intr<=0;
  end
  else if (ether_ack) begin
    temp_intr<=1;
  end
  else if(temp_intr==1 && enet_cs)
    temp_intr<=0;

end


/*指令存储器*/
//imem imem(ip_in[12:2],inst);
//imemory im(pc,inst);
dist_iram_ip IMEM (
  .a(ip_in[12:2]),      // input wire [10 : 0] a
  .spo(inst)  // output wire [31 : 0] spo
);

wire [31:0]addr_in=addr-32'h10010000;

/*数据存储器*/
dist_dmem_ip DMEM (
  .a(addr_in[16:2]),      // input wire [10 : 0] a
  .d(wdata),      // input wire [31 : 0] d
  .clk(clk),  // input wire clk
  .we(dmem_cs&DM_W),    // input wire we
  .spo(data_fmem)  // output wire [31 : 0] spo
);




vga vga_inst(
.clk_in(clk_vga),//25M
.clk100(clk_in),
.rst(rst),
.idata(wdata),
.cs(vga_cs&DM_W),
.hsync(hsync),
.vsync(vsync),
.vga_r(vga_r),
.vga_g(vga_g),
.vga_b(vga_b)
    );


EthernetR etr_inst(
.clk(clk_in), 
.rst(rst),
.MDIO(MDIO),
.MDC(MDC),
.RESET(RESET),
.RXD0(RXD0),
.RXD1(RXD1),
.RXERR(RXERR),
.TXD0(TXD0),
.TXD1(TXD1),
.TXEN(TXEN),
.CRS_DV(CRS_DV),
.REF_CLKO(REF_CLKO),
.CLKIN(CLKIN),
.receive_ack(ether_ack),
.odata(eth_data)
    );

assign rdata = enet_cs?eth_data:data_fmem;

// seg7x16 sx_inst(
// .clk(clk_in),
// .reset(rst),
// .cs(1),
// .i_data(eth_data),
// //.i_data(wdata),
// .o_seg(o_seg),
// .o_sel(o_sel)
//     );
endmodule
