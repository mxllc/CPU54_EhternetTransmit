`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/28 20:36:24
// Design Name: 
// Module Name: DIV
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


module DIV( 
    input signed [31:0]dividend,//被除数 
    input signed [31:0]divisor,//除数 
    input start,//启动除法运算  
    input clock, 
    input reset, 
    output [31:0]q,//商 
    output reg [31:0]r,//余数     
    output reg busy,//除法器忙标志位 
    output reg over
);
reg[5:0]count; 
reg signed [31:0] reg_q; 
reg signed [31:0] reg_r; 
reg signed [31:0] reg_b; 
reg r_sign; 

wire [32:0] sub_add = r_sign?({reg_r,q[31]} + {1'b0,reg_b}):({reg_r,q[31]} - {1'b0,reg_b});//加、减法器 

// assign q = reg_q;    
// wire signed[31:0] tq=(dividend[31]^divisor[31])?(-reg_q):reg_q;
assign q = reg_q;     
always @ (posedge clock or posedge reset)
begin 
    if (reset)
        begin//重置 
            count <=0; 
            busy <= 0; 
            over<=0;
        end
    else
        begin 
            if (start) 
                begin//开始除法运算，初始化 
                    reg_r <= 0; 
                    r_sign <= 0; 
                    count <= 0; 
                    busy <= 1; 
                    if(dividend<0)
                        reg_q <= -dividend;
                    else
                        reg_q <= dividend;
                    if(divisor<0)
                        reg_b <= -divisor; 
                    else
                        reg_b <= divisor; 
                end 
            else if (busy) 
                begin
                    if(count<=31)
                        begin 
                            reg_r <= sub_add[31:0];//部分余数 
                            r_sign <= sub_add[32];//如果为负，下次相加 
                            reg_q <= {reg_q[30:0],~sub_add[32]};//上商
                            count <= count +1;//计数器加一 
                        end
                    else
                        begin
                            if(dividend[31]^divisor[31])
                                reg_q<=-reg_q;
                            if(!dividend[31])
                                r<=r_sign? reg_r + reg_b : reg_r;
                            else
                                r<=-(r_sign? reg_r + reg_b : reg_r);
                            busy <= 0;
                            over <= 1;
                        end
                end
            else
            over<=0;
        end 
end 
endmodule