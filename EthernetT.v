`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/24 09:17:28
// Design Name: 
// Module Name: EthernetT
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


module EthernetT(
input clk, 
input cs,
inout MDIO,
output MDC,
output RESET,
inout RXD0,
inout RXD1,
inout RXERR,
output TXD0,
output TXD1,
output reg TXEN,
inout CRS_DV,
inout REF_CLKO,
output CLKIN,

input button_u,
input button_d,
input button_l,
input button_r,
input [15:0]sw,
output [7:0] o_seg,
output [7:0] o_sel
);

wire rst=button_r;
wire clk_button;
reg[31:0]seg_data;
assign MDIO=1;
assign RESET=1;
Divider #(2)clk50(clk,rst,CLKIN);
Divider #(20)clk5(clk,rst,MDC);
Divider #(5000_0000)clk0(clk,rst,clk_button);

reg start;

localparam IDLE=0,
            SEND_DATA=1,
            SEND_END=2;

reg [3:0]cur_st;



reg [6:0]count;
reg [2:0]count4;

always@(posedge clk)begin
    if(cs)
        start<=1;
    else
        start<=0;
    end

// assign {TXD0,TXD1}=(cur_st==SEND_DATA)?odata_tmp[575:574]:2'b00;


always @(negedge CLKIN or posedge rst) begin
    if (rst) begin
        cur_st<=IDLE;
    end
    else begin
        case(cur_st)
            IDLE:if(start) cur_st<=SEND_DATA;
            SEND_DATA:   if(count==72) cur_st<=SEND_END; //计数从0到288
                            else cur_st<=cur_st;
            SEND_END: if(start==0)cur_st<=IDLE; 
                            else cur_st<=cur_st;
            default: cur_st<=IDLE;
    endcase
    end
end

//count
always@(negedge CLKIN or posedge rst)
    if (rst)begin
        count<=0;
    end
    else if(count4==3)
        count<=count+1;
    else if(cur_st==IDLE)
        count<=0;
    else
        count<=count;

//count4
always@(negedge CLKIN or posedge rst)
    if (rst)begin
        count4<=0;
    end
    else if(cur_st==SEND_DATA)
        if (count4==3) begin
            count4<=0;
        end
        else begin
            count4<=count4+1;
        end
    else
        count4<=0;




wire [7:0]temp,temp_t;
reg [31:0]Data;
always @(posedge clk)
    if(cs)
        Data<=seg_data;

dist_mem_gen_0 mem(count,temp_t);


assign temp=count==22?Data[31:24]:
            count==23?Data[23:16]:
            count==24?Data[15:8]:
            count==25?Data[7:0]:
            temp_t;


assign {TXD0,TXD1}=count4==0?temp[7:6]:
                       count4==1?temp[5:4]:
                       count4==2?temp[3:2]:
                       temp[1:0];



//TXEN
always@(negedge CLKIN or posedge rst)
    if (rst)
        TXEN<=0;
    else if(cur_st==IDLE && start)
        TXEN<=1;
    else if(cur_st==SEND_DATA)begin
        if ((count == 71 && count4 == 3)||TXEN==0) begin
            TXEN<=0;
        end
        else begin
            TXEN<=1;
        end
    end
    else
        TXEN<=0;




seg7x16 sx_inst(
.clk(clk),
.reset(rst),
.cs(1),
.i_data(seg_data),
.o_seg(o_seg),
.o_sel(o_sel)
    );

wire[31:0]high_data={sw,seg_data[15:0]};
wire[31:0]low_data={seg_data[31:16],sw};

always @(posedge clk_button or posedge rst) begin
    if (rst) begin
//        seg_data<=32'h1234_5678;
        seg_data<=32'h0;
    end
    else if (button_u) begin
        seg_data<=high_data;
    end
    else if (button_d) begin
        seg_data<=low_data;
    end
    else if (button_l) begin
        seg_data<=32'd0;
    end
    // else if (button_r) begin
    //     seg_data<=seg_data-32'h1000;
    // end
    else begin
        seg_data<=seg_data;
    end
end


endmodule

module Divider(I_CLK,Rst,O_CLK);
    parameter times =20;
    input I_CLK,Rst;
    output O_CLK;
    reg temp=1'b0;
    parameter tmp_times=times/2;
    
    assign O_CLK=temp;
    
    integer cnt=0;
    
    always @(posedge I_CLK)
    begin
       if(Rst==1'b1)
       begin
           cnt<=0;
           temp<=1'b0;
       end
       else
       begin
           if(cnt==tmp_times-1)
           begin
               temp<=~temp;
               cnt<=0;
           end
           else
               cnt<=cnt+1;  
       end
    end
endmodule