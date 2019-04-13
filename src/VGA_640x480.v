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
	input wire clk,//分频的时钟，频率为25mhz
	input wire rst,
	input [31:0] data2,
	output HS,
	output VS,
	output valid,
    output [31:0] o_data,
    output intr,
    output rstart
    );

	reg [31:0]h_count;
	reg [31:0]v_count;
	wire[9:0]xpos;
	wire[9:0]ypos;

	localparam vga_x=640;
	localparam vga_y=480;
	localparam pict_x=640;
	localparam pict_y=480;

	localparam pict_num=6;
	localparam play_time_num=2;
	// every 5 pictures is played. the display time between two pictures is less than 0.1
	// localparam addr_num=pict_x/32*pict_y;

	reg[14:0]addr;
	reg[3:0]pict_count;
	reg[4:0]play_time_count;
	wire[31:0]tdata;

	reg[31:0]data1;
	reg req;//32位的数据用完，向cpu请求数据
	reg ini;//初始化，向cpu请求数据
	reg flag;
	reg restart;
	// reg flag_2_to_1;//rst之后 把data2给data1
	assign rstart = restart;

	// assign o_data = ((xpos<pict_x) && (ypos < pict_y))?tdata:32'd0;
	// assign o_data = (play_time_count>0)?32'd0:(((xpos<pict_x) && (ypos < pict_y))?data1:32'd0);
	assign o_data = (play_time_count>0)?32'd0:(((xpos<pict_x) && (ypos < pict_y))?((xpos%32==0)?data2:data1):32'd0);




	//ini flag
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			ini<=0;
			flag<=0;
		end
		else if (h_count== 10'd96 && flag==0) begin
			ini<=1;
			flag<=1;
		end
		else begin
			ini<=0;
		end
	end


	assign intr = ini|req;




	// req
	// data1
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			req<=0;
			data1<=32'hffffffff;
//			data1<=32'h0;
		end
		else if (valid) begin
			if (xpos % 32 == 0 && (xpos<pict_x) && (ypos <pict_y)) begin//进一步判读是否需要发出req
				if ((ypos == pict_y - 1) && (xpos == pict_x - 32)) begin//在一帧图像的结尾
					if(play_time_count==play_time_num-1)begin//一帧图播放到最后一次
						req<=1;
						data1<=data2;
					end
					else begin
						req<=0;
						data1<=data2;
					end
				end
				else begin
					if (play_time_count == 0) begin
						req<=1;
						data1<=data2;
					end
					else begin
						req<=0;
						data1<=data1;// play_time_count>0的时候 上面已经操作过使得o_data=0
					end
				end
			end
			else begin
				req<=0;
				data1<=data1;
			end
		end
		else begin
			req<=0;
			data1<=data1;
		end
	end

	// restart
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			restart<=0;
		end
		else if (valid && (xpos % 32 == 0) && (ypos == pict_y - 1) && (xpos == pict_x - 32) && (play_time_count==play_time_num-1) &&(pict_count == pict_num - 1)) begin
			restart<=1;
		end
		else if(v_count == 0)begin
			restart<=0;
		end
		else begin
			restart<=restart;
		end
	end


	//play_time_count
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// reset
			play_time_count<=0;
		end
		else if ((ypos == vga_y - 1) && (xpos == vga_x -1)) begin
			if(play_time_count == play_time_num-1)begin
				play_time_count<=0;
			end
			else begin
				play_time_count<=play_time_count+1;
			end
		end
		else begin
			play_time_count<=play_time_count;
		end
	end

	// pict_count
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			pict_count<=0;
		end
		else if ((ypos == vga_y - 1) && (xpos == vga_x -1) && (play_time_count == play_time_num-1)) begin
			if(pict_count == pict_num - 1)begin
				pict_count<=0;
			end
			else begin
				pict_count<=pict_count+1;
			end
		end
		else begin
			pict_count<=pict_count;
		end
	end




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