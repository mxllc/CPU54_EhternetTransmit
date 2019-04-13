`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/09 09:56:40
// Design Name: 
// Module Name: VGA_Color
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


module VGA_Color(
input clk,
input rst,
input valid,
input [31:0]data,
output reg[3:0]red,
output reg[3:0]green,
output reg[3:0]blue
    );

reg [4:0]count;//at most of 31
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		count<=0;
	end
	else if (valid) begin
		count<=count+1;
	end
	else begin
		count <=0;
	end
end

always @(*) begin
    if (valid) begin
    	if(data[31-count]==0)begin
    		red=4'b0000;green=4'b0000;blue=4'b0000;//black
    	end
    	else begin
    		red=4'b1111;green=4'b1111;blue=4'b1111;//white
    	end
    end
    else begin
         red=4'b0000;green=4'b0000;blue=4'b0000;
    end
end
endmodule
