`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/24 10:10:34
// Design Name: 
// Module Name: EthernetR
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


module EthernetR(
input clk, 
input rst,
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
output receive_ack,
output[31:0]odata
    );

    assign MDIO=1;
    assign RESET=1;
    assign {TXD1,TXD0}=2'b0;
    always @(posedge clk)
        TXEN<=0;

    Divider #(2) clk50(clk,1'b0,CLKIN);
    Divider #(20)clk5(clk,1'b0,MDC);


    reg [3:0]cur_st;
    reg [6:0]count;
    reg [1:0]count4;
    reg [7:0]temp;
    reg [3:0]status;

    localparam IDLE=0,
           RECEIVE=1,
           RECEIVE_END=2;
    

    always@(posedge CLKIN or posedge rst)begin
        if (rst) begin
            cur_st<=IDLE;
        end
        else begin
            case(cur_st)
                IDLE: if(CRS_DV & RXD0 & RXD1) cur_st<=RECEIVE;//SDF :1010_1011
                RECEIVE: if(status==0 && count4 !=0) cur_st<=RECEIVE_END;
                        else cur_st<=RECEIVE;
                RECEIVE_END: cur_st<=IDLE;
                default: cur_st<=IDLE;
            endcase
        end 
    end

    //count
    always@(posedge CLKIN or posedge rst)
        if (rst)
            count<=0;
        else if(cur_st==IDLE)
            count<=0;
        else if(count4==3)
            count<=count+1;
        else
            count<=count;

    //count4
    always@(posedge CLKIN or posedge rst)
        if (rst)begin
            count4<=0;
        end
        else if(cur_st==IDLE)
            count4<=0;
        else if(cur_st==RECEIVE)begin
            if (count4==3) 
                count4<=0;
            else
                count4<=count4+1;
        end
        else
            count4<=count4;

    
    reg [7:0]mem[0:127];
    always @(posedge CLKIN)begin
        if(count4==0)
            temp[7:6]<={RXD1,RXD0};
        else if(count4==1)
            temp[5:4]<={RXD1,RXD0};
        else if(count4==2)
            temp[3:2]<={RXD1,RXD0};
        else 
            temp[1:0]<={RXD1,RXD0};
    end

    always @(posedge CLKIN or posedge rst)begin
        if(rst)
            status=0;
        else if(cur_st==RECEIVE)
            status[count4]<=CRS_DV;
        else begin
            status=0;
        end
    end
  
    always @(posedge CLKIN)begin
        if(cur_st==RECEIVE && count4==0 && status!=0)
            mem[count-1]<=temp;
    end

    assign odata={mem[14],mem[15],mem[16],mem[17]};
    assign receive_ack=(cur_st==RECEIVE_END)?1:0;

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