`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/04/15 15:11:16
// Design Name: 
// Module Name: CPU31
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


module CPU54(
input clk,
input rst,
input [31:0]instruction,//指令
input [31:0]rdata,//从内存中读取来的数据
output reg[31:0]PC,//指令的位置
output [31:0]addr,//在内存的中的位置
output reg[31:0]wdata,//存入内存的数据
output IM_R,//
output DM_CS,//内存片选有效
output DM_R,//内存读
output DM_W,//内存写
input intr,
output inta
    );

// wire clk;
// wire rst=ori_rst;
// wire locked;


assign inta=1'b1;
assign IM_R = 1'b1;
 

wire [3:0]aluc;
wire ALU_a;
wire ALU_b;



wire [31:0]NPC=PC+32'd4;
//wire [31:0]IPC=PC-32'h00400000;//哈佛结构的指令映射


//alu
wire [31:0]alu_a;
wire [31:0]alu_b;
wire [31:0]alu_r;
wire zero;


wire rf_write;//寄存器堆写信号
wire [4:0]rs;
wire [4:0]rt;
wire [4:0]rd;
wire [4:0]rf_raddr1;
wire [4:0]rf_raddr2;
wire [4:0]rf_waddr;
wire [31:0]rf_rdata1;
wire [31:0]rf_rdata2;
reg [31:0]rf_wdata;

wire [2:0]rf_wd;
wire [1:0]rf_wa;

wire sign_extend;
wire intr_to_cp0;

//sb,sh
wire [1:0]sb_r=addr[1:0];//判断0 1 2 3
wire sh_r=addr[1];//判断 0 1

//
wire [1:0]lb_r=addr[1:0];
wire lh_r=addr[1];

wire [31:0]MemDataS8 = lb_r[1]?(lb_r[0]?{{24{rdata[31]}}, rdata[31:24]}:{{24{rdata[23]}}, rdata[23:16]}):(lb_r[0]?{{24{rdata[15]}}, rdata[15:8]}:{{24{rdata[7]}}, rdata[7:0]});
wire [31:0]MemDataZ8 = lb_r[1]?(lb_r[0]?{24'd0, rdata[31:24]}:{24'd0, rdata[23:16]}):(lb_r[0]?{24'd0, rdata[15:8]}:{24'd0, rdata[7:0]});

wire [31:0]MemDataS16 = lh_r?{{16{rdata[31]}}, rdata[31:16]}:{{16{rdata[15]}}, rdata[15:0]};
wire [31:0]MemDataZ16 = lh_r?{16'd0, rdata[31:16]}:{16'd0, rdata[15:0]};



wire jump_26;
wire beq;
wire bne;
wire jr;
wire bgez;
wire clz;
wire [31:0]clz_result;
wire div;
wire divu;
wire [31:0]q_div;
wire [31:0]r_div;
wire [31:0]q_divu;
wire [31:0]r_divu;

//cp0
wire mfc0;
wire mtc0;
wire BREAK;
wire eret;
wire syscall;
wire teq;
wire [4:0]cause;
wire [31:0]rdata_cp0;
wire [31:0]exc_addr;
wire exception=BREAK|syscall|(teq&zero);
wire [31:0]status;


wire [15:0]instr_low16=instruction[15:0];

wire jump_16=(beq&zero)|(bne&(~zero))|(bgez&(~rf_rdata1[31]));
wire [25:0]instr_index=instruction[25:0];
wire [5:0]instr_op=instruction[31:26];



wire [31:0]EXTZ5={27'b0,instruction[10:6]};
wire [31:0]EXTZ16={16'b0,instr_low16};
wire [31:0]EXTS16={{16{instr_low16[15]}},instr_low16};


wire mthi;
wire mtlo;
wire jarl;
wire [1:0]RMemMode;
wire sign_lblh;
wire [1:0]WMemMode;
wire multu;

wire signed [31:0]mul_a=rf_rdata1;
wire signed [31:0]mul_b=rf_rdata2;
wire signed [31:0]mul_z = mul_a*mul_b;

wire [31:0]multu_a=rf_rdata1;
wire [31:0]multu_b=rf_rdata2;
wire [63:0]multu_z=rf_rdata1*rf_rdata2;


wire busy_div;
wire busy_divu;

reg start_div;
reg start_divu;
wire over_div;
wire over_divu;

wire busy=busy_div|busy_divu|(div&(~over_div))|(divu&(~over_divu));
always @(posedge clk or posedge rst) begin
  if (rst) begin
    start_div<=1'b0;
  end
  else if (!div) begin
    start_div<=1'b0;
  end
  else if (div&(~busy_div)&(~over_div)) begin
    start_div<=1'b1;
  end
  else begin
    start_div<=1'b0;
  end
end

always @(posedge clk or posedge rst) begin
  if (rst) begin
    start_divu<=1'b0;
  end
  else if (!divu) begin
    start_divu<=1'b0;
  end
  else if (divu&(~busy_divu)&(~over_divu)) begin
    start_divu<=1'b1;
  end
  else begin
    start_divu<=1'b0;
  end
end


assign intr_to_cp0 = intr & (~jump_16) & (~jump_26) & (~jr) & (~jarl);

//PC
always @(posedge clk or posedge rst) begin
  if (rst) begin
    PC<=32'h00400000;
  end
  else if (jump_16) begin
    PC<=NPC+{{14{instr_low16[15]}},instr_low16,2'b00};
  end
  else if (jump_26) begin
    PC<={PC[31:28],instr_index,{2'b00}};
  end
  else if (jr|jarl) begin
    PC<=rf_rdata1;
  end
  else if (exception| eret) begin
    PC<=exc_addr;
  end
  else if (busy) begin
    PC<=PC;
  end
  else if (intr_to_cp0 & status[4]) begin
    PC<=exc_addr;
  end
  else begin
    PC<=NPC;
  end
end

reg [31:0]HI;
reg [31:0]LO;

// wire [31:0]hi;
// wire [31:0]lo;


//HI 注意：上升沿修改。
always @(posedge clk or posedge rst) begin
  if(rst)begin
    HI<=32'h00000000;
  end
  else begin
    if (mthi)begin
      HI<=rf_rdata1;
    end
    else if (multu) begin
      HI<=multu_z[63:32];
    end
    else if (over_div) begin
      HI<=r_div;
    end
    else if (over_divu) begin
      HI<=r_divu;
    end
    else begin
      HI<=HI;
    end
  end
end

//LO 注意：上升沿修改。
always @(posedge clk or posedge rst) begin
  if(rst)begin
    LO<=32'h00000000;
  end
  else begin
    if (mtlo)begin
      LO<=rf_rdata1;
    end
    else if (multu) begin
      LO<=multu_z[31:0];
    end
    else if (over_div) begin
      LO<=q_div;
    end
    else if (over_divu) begin
      LO<=q_divu;
    end
    else begin
      LO<=LO;
    end
  end
end




assign rs=instruction[25:21];
assign rt=instruction[20:16];
assign rd=instruction[15:11];

wire rf_write_zero_check = rf_write & (rf_waddr==5'b0 ? 1'b0 :1'b1);

Regfiles rfl(.clk(clk),.rst(rst),.wena(rf_write_zero_check),.raddr1(rf_raddr1),.raddr2(rf_raddr2),.waddr(rf_waddr),.wdata(rf_wdata),.rdata1(rf_rdata1),.rdata2(rf_rdata2));


alu al(.a(alu_a),.b(alu_b),.aluc(aluc), .r(alu_r),.zero(zero),.carry(),.negative(),.overflow());



assign DM_CS = DM_W | DM_R;



assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
// assign rf_waddr = jal?5'd31:(rf_wa?rd:rt);//54条可能需要把rf_Wa修改成两位--优化
// assign rf_waddr = rf_wa[1]?(rf_wa[0]?5'd31:mfc0...):(rf_wa[0]?rd:rt);
assign rf_waddr = rf_wa[1]?(rf_wa[0]?5'd31:rt):(rf_wa[0]?rd:rt);



assign addr = rf_rdata1 + (sign_extend ? EXTS16:EXTZ16);//需要加入控制信号**** lw sw************************************
// assign wdata = rf_rdata2;




// wire [31:0]Wdata_sb=sb_r[1]?(sb_r[0]?{rf_rdata2[7:0],rdata[23:0]}:{rdata[31:24],rf_rdata2[7:0],rdata[15:0]}):(sb_r[0]?{rdata[31:16],rf_rdata2[7:0],rdata[7:0]}:{rdata[31:8],rf_rdata2[7:0]});
wire [31:0]Wdata_sh= sh_r?{rf_rdata2[15:0],rdata[15:0]}:{rdata[31:16],rf_rdata2[15:0]};
reg [31:0]Wdata_sb;
always @(*) begin
  case(sb_r)
  2'b11:Wdata_sb={rf_rdata2[7:0],rdata[23:0]};
  2'b10:Wdata_sb={rdata[31:24],rf_rdata2[7:0],rdata[15:0]};
  2'b01:Wdata_sb={rdata[31:16],rf_rdata2[7:0],rdata[7:0]};
  2'b00:Wdata_sb={rdata[31:8],rf_rdata2[7:0]};
  default:Wdata_sb={rdata[31:8],rf_rdata2[7:0]};
  endcase
end



// assign wdata = (WMemMode==2'b01)?Wdata_sh:((WMemMode==2'b00)?Wdata_sb:rf_rdata2);
always @(*) begin
  case(WMemMode)
    2'b11:wdata=rf_rdata2;
    2'b10:wdata=rf_rdata2;
    2'b01:wdata=Wdata_sh;
    2'b00:wdata=Wdata_sb;
    default:wdata=rf_rdata2;

  endcase
end




// assign rf_wdata=jal? NPC :(rf_wd?alu_r:rdata);//54条可能需要把rf_wd修改成两位--优化
// assign rf_wdata = rf_wd[1]?(rf_wd[0]?NPC:rdata_cp0):(rf_wd[0]?alu_r:rdata);


// assign rf_wdata = rf_wd[2]?(rf_wd[1]?(rf_wd[0]?mul_z:clz_result):(rf_wd[0]?HI:LO)):(rf_wd[1]?(rf_wd[0]?NPC:rdata_cp0):(rf_wd[0]?alu_r:(RMemMode[1]?rdata:(RMemMode[0]?(sign_lblh?MemDataS16:MemDataZ16):(sign_lblh?MemDataS8:MemDataZ8)))));
// assign rf_wdata = rf_wd[2]?(rf_wd[0]?HI:LO):(rf_wd[1]?(rf_wd[0]?NPC:rdata_cp0):(rf_wd[0]?alu_r:rdata));
 // assign rf_wd = mfhi?3'b101:(mflo?:3'b100:(mfc0?3'b010:(jal?3'b011:(lw?3'b000:3'b001))));



always @(*) begin
  case(rf_wd) 
    3'b111:rf_wdata=mul_z;
    3'b110:rf_wdata=clz_result;
    3'b101:rf_wdata=HI;
    3'b100:rf_wdata=LO;

    3'b010:rf_wdata=rdata_cp0;
    3'b011:rf_wdata=NPC;
    3'b000:
      case(RMemMode)
        2'b11:rf_wdata=rdata;
        2'b10:rf_wdata=rdata;
        2'b01:rf_wdata=sign_lblh?MemDataS16:MemDataZ16;
        2'b00:rf_wdata=sign_lblh?MemDataS8:MemDataZ8;
        default:rf_wdata=rdata;
      endcase
    3'b001:rf_wdata=alu_r;
    default:rf_wdata=alu_r;
  endcase
end



assign alu_a = ALU_a?rf_rdata1:EXTZ5;
assign alu_b = ALU_b?rf_rdata2:(sign_extend ? EXTS16:EXTZ16);


CONTROL con_inst(.instruction(instruction),.aluc(aluc),.rf_write(rf_write),.DM_W(DM_W),.DM_R(DM_R),.sign_extend(sign_extend),.ALU_a(ALU_a),.ALU_b(ALU_b),.rf_wd(rf_wd),
  .rf_wa(rf_wa),.jump_26(jump_26),.beq(beq),.bne(bne),.jr(jr), .mfc0(mfc0), .mtc0(mtc0), .BREAK(BREAK), .eret(eret), .syscall(syscall), .teq(teq), .cause(cause), .mthi(mthi),
.mtlo(mtlo),.jarl(jarl),.RMemMode(RMemMode),.sign_lblh(sign_lblh),.WMemMode(WMemMode),.bgez(bgez),.clz(clz),.multu(multu),.div(div),.divu(divu));




CP0 cp0_inst(.clk(clk), .rst(rst), .mfc0(mfc0), .mtc0(mtc0), .pc(PC), 
.Rd(rd),        //考虑  [2:0]  sel 
.wdata(rf_rdata2),    // rt中读取出来  rf_raddr2 = rt;
.exception(exception), 
.eret(eret),
.cause(cause), 
.intr(intr_to_cp0), 
.rdata(rdata_cp0),      // Data from CP0 register for GP register 
.status(status), 
.timer_int(), 
.exc_addr(exc_addr)    // Address for PC at the beginning of an exception 
); 

CLZ clz_inst(.in(rf_rdata1),.out(clz_result));

DIV div_inst(.dividend(rf_rdata1),.divisor(rf_rdata2),.start(start_div),.clock(clk),.reset(rst),.q(q_div),.r(r_div),.busy(busy_div),.over(over_div));
DIVU divu_inst(.dividend(rf_rdata1),.divisor(rf_rdata2),.start(start_divu),.clock(clk),.reset(rst),.q(q_divu),.r(r_divu),.busy(busy_divu),.over(over_divu));
endmodule
