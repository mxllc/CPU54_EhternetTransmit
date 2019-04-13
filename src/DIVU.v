`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/28 19:11:17
// Design Name: 
// Module Name: DIVU
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


module DIVU(
	input [31:0]dividend,         //被除数
    input [31:0]divisor,          //除数
    input start,                  //启动除法运算
    input clock,
    input reset,
    output [31:0]q,               //商
    output [31:0]r,               //余数    
    output reg busy,                   //除法器忙标志位
    output reg over
    );

	reg [4:0]count;
	reg [31:0] reg_q;
	reg [31:0] reg_r;
	reg [31:0] reg_b;
	reg r_sign;
	wire [32:0] sub_add = r_sign?({reg_r,q[31]} + {1'b0,reg_b}):({reg_r,q[31]} - {1'b0,reg_b});    //加、减法器
	assign r = r_sign? reg_r + reg_b : reg_r;
	assign q = reg_q; 


	always @(posedge clock or posedge reset) begin
		if (reset) begin
			busy<=0;
			count<=0;
            over<=0;
		end
		else begin
			if (start) begin
				reg_q<=dividend;
				reg_b<=divisor;
				reg_r<=32'b0;
				count<=0;
				busy<=1;
				r_sign<=0;
			end
			else if (busy) begin
				reg_r<=sub_add[31:0];
				reg_q<={reg_q[30:0],~sub_add[32]};
				r_sign<=sub_add[32];
				count<=count +5'b1;
				if(count == 5'd31)begin
					busy<=0;
					over<=1;
				end
			end
			else begin
			     over<=0;
			end
		end

	end
endmodule
