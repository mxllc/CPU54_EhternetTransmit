`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/04 23:27:20
// Design Name: 
// Module Name: VGA_640x480
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
module VGA_640x480(
    input clk,//分频的时钟，频率为25mhz
    input rst,
    output HS,
    output VS,
    output valid,
    output [31:0] xpos,
    output [31:0] ypos
    );

    reg [31:0]h_count;
    reg [31:0]v_count;  
    



    //行计数：h_count(0-639+8+8+96+40+8 = 799)
    always@(posedge clk or posedge rst)begin
        if (rst) begin
            h_count<=0;
        end
        else if(h_count == 10'd799)
            h_count <= 10'h0;
        else
            h_count <= h_count + 10'h1;
    end

    
    //帧计数：v_count(0-524)
    always@(posedge clk or posedge rst)begin
        if (rst) begin
            v_count<=0;
        end
        else if(h_count == 10'd799)begin        
            if(v_count == 10'd524)v_count <= 10'h0;
            else v_count <= v_count + 10'h1;
        end
    end


    assign xpos = valid?(h_count - 10'd143):0;
    assign ypos = valid?(v_count - 10'd35):0;
    assign VS = (v_count >= 10'd2);
    assign HS = (h_count >= 10'd96);
    assign valid = (((h_count >= 10'd143)&&(h_count < 10'd783)) && ((v_count >= 10'd35) && (v_count < 10'd515)));        
    
endmodule 