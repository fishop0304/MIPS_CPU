`include "define.v"
`include "pc_reg.v"
`include "if_id.v"
`include "id.v"
`include "regfile.v"
`include "id_ex.v"
`include "ex.v"
`include "ex_mem.v"
`include "mem.v"
`include "mem_wb.v"
`include "hilo_reg.v"

module openmips(
	input	wire		clk,
	input	wire		rst,
	 
	input	wire[`RegBus]	rom_data_i,
	output	wire[`RegBus]	rom_addr_o,
	output	wire            rom_ce_o
);
wire	[`InstAddrBus]	pc;
wire	[`InstAddrBus]	id_pc_i;
wire	[`InstBus]		id_inst_i;
//============= ID -> ID/EX =============// 
wire	[`AluOpBus] 	id_aluop_o;
wire	[`AluSelBus] 	id_alusel_o;
wire	[`RegBus] 		id_reg1_o;
wire	[`RegBus] 		id_reg2_o;
wire					id_wreg_o;
wire	[`RegAddrBus] 	id_wd_o;
//============= ID/EX -> EX =============// 
wire	[`AluOpBus] 	ex_aluop_i;
wire	[`AluSelBus] 	ex_alusel_i;
wire	[`RegBus] 		ex_reg1_i;
wire	[`RegBus] 		ex_reg2_i;
wire	 				ex_wreg_i;
wire	[`RegAddrBus] 	ex_wd_i;
//============= EX -> EX/MEM =============// 
wire 					ex_wreg_o;
wire	[`RegAddrBus] 	ex_wd_o;
wire	[`RegBus]	 	ex_wdata_o;
wire	[`RegBus]	 	ex_hi_o;
wire	[`RegBus]	 	ex_lo_o;
wire 					ex_whilo_o;
//============= EX/MEM -> MEM =============// 
wire 					mem_wreg_i;
wire	[`RegAddrBus] 	mem_wd_i;
wire	[`RegBus]	 	mem_wdata_i;
wire	[`RegBus]	 	mem_hi_i;
wire	[`RegBus]	 	mem_lo_i;
wire 					mem_whilo_i;
//============= MEM -> MEM/WB =============// 
wire 					mem_wreg_o;
wire	[`RegAddrBus] 	mem_wd_o;
wire	[`RegBus]	 	mem_wdata_o;
wire	[`RegBus]	 	mem_hi_o;
wire	[`RegBus]	 	mem_lo_o;
wire 					mem_whilo_o;
//============= MEM/WB -> REG =============// 
wire 					wb_wreg_i;
wire	[`RegAddrBus]	wb_wd_i;
wire	[`RegBus]		wb_wdata_i;
wire	[`RegBus]		wb_hi_i;
wire	[`RegBus]		wb_lo_i;
wire 					wb_whilo_i;
//============= ID -> REG =============// 
wire 					reg1_read;
wire 					reg2_read;
wire	[`RegBus]	 	reg1_data;
wire	[`RegBus]	 	reg2_data;
wire	[`RegAddrBus] 	reg1_addr;
wire	[`RegAddrBus] 	reg2_addr;
//============= MEM/WB -> HILO =============// 
wire	[`RegBus]	 	hi;
wire	[`RegBus]		lo;

assign rom_addr_o = pc;

pc_reg pc_reg0(
	.clk	(clk),
	.rst	(rst),
	.pc		(pc),
	.ce		(rom_ce_o)	
);
//==========//====\\==========//
//==========|| PC ||==========//
//==========\\====//==========//
if_id if_id0(
	.clk(clk), .rst(rst),
	//===== INPUT PC =====//
	.if_pc		(pc),
	.if_inst	(rom_data_i),
	//===== OUTPUT ID =====//
	.id_pc		(id_pc_i),
	.id_inst	(id_inst_i)      	
);
//==========//====\\==========//
//==========|| ID ||==========//
//==========\\====//==========//
id id0(
	.rst			(rst),
	//===== PC -> ID =====//
	.pc_i			(id_pc_i),
	.inst_i			(id_inst_i),
	//===== REG -> ID =====//
	.reg1_data_i	(reg1_data),
	.reg2_data_i	(reg2_data),
	//===== EX -> ID =====//
	.ex_wreg_i		(ex_wreg_o),
	.ex_wd_i		(ex_wd_o),
	.ex_wdata_i		(ex_wdata_o),
	//===== MEM -> ID =====//
	.mem_wreg_i		(mem_wreg_o),
	.mem_wd_i		(mem_wd_o),
	.mem_wdata_i	(mem_wdata_o),
	//===== ID -> REG =====//
	.reg1_read_o	(reg1_read),
	.reg2_read_o	(reg2_read), 	  
	.reg1_addr_o	(reg1_addr),
	.reg2_addr_o	(reg2_addr), 
	//===== ID -> ID/EX =====//
	.aluop_o		(id_aluop_o),
	.alusel_o		(id_alusel_o),
	.reg1_o			(id_reg1_o),
	.reg2_o			(id_reg2_o),
	.wd_o			(id_wd_o),
	.wreg_o			(id_wreg_o)
);
//==========//=======\\==========//
//==========|| ID/EX ||==========//
//==========\\=======//==========//
id_ex id_ex0(
	.clk(clk), .rst(rst),
	//===== INPUT ID =====//
	.id_aluop	(id_aluop_o),
	.id_alusel	(id_alusel_o),
	.id_reg1	(id_reg1_o),
	.id_reg2	(id_reg2_o),
	.id_wd		(id_wd_o),
	.id_wreg	(id_wreg_o),
	//===== OUTPUT EX =====//
	.ex_aluop	(ex_aluop_i),
	.ex_alusel	(ex_alusel_i),
	.ex_reg1	(ex_reg1_i),
	.ex_reg2	(ex_reg2_i),
	.ex_wd		(ex_wd_i),
	.ex_wreg	(ex_wreg_i)
);		
//==========//====\\==========//
//==========|| EX ||==========//
//==========\\====//==========//
ex ex0(
	.rst			(rst),
	//===== ID/EX -> EX =====//
	.aluop_i		(ex_aluop_i),
	.alusel_i		(ex_alusel_i),
	.reg1_i			(ex_reg1_i),
	.reg2_i			(ex_reg2_i),
	.wd_i			(ex_wd_i),
	.wreg_i			(ex_wreg_i),
	//===== MEM -> EX =====//
	.mem_hi_i		(mem_hi_o),
	.mem_lo_i		(mem_lo_o),
	.mem_whilo_i	(mem_whilo_o),
	//===== MEM/WB -> EX =====//
	.wb_hi_i		(wb_hi_i),
	.wb_lo_i		(wb_lo_i),
	.wb_whilo_i		(wb_whilo_i),
	//===== HILO -> EX =====//
	.hi_i			(hi),
	.lo_i			(lo),
	//===== EX -> EX/MEM =====//
	.wd_o			(ex_wd_o),
	.wreg_o			(ex_wreg_o),
	.wdata_o		(ex_wdata_o),
	.hi_o			(ex_hi_o),
	.lo_o			(ex_lo_o),
	.whilo_o		(ex_whilo_o)
);
//==========//========\\==========//
//==========|| EX/MEM ||==========//
//==========\\========//==========//
ex_mem ex_mem0(
	.clk(clk), .rst(rst),
	//===== INPUT EX =====//
	.ex_wd		(ex_wd_o),
	.ex_wreg	(ex_wreg_o),
	.ex_wdata	(ex_wdata_o),
	.ex_hi		(ex_hi_o),
	.ex_lo		(ex_lo_o),
	.ex_whilo	(ex_whilo_o),
	//===== OUTPUT MEM =====//
	.mem_wd		(mem_wd_i),
	.mem_wreg	(mem_wreg_i),
	.mem_wdata	(mem_wdata_i),
	.mem_hi		(mem_hi_i),
	.mem_lo		(mem_lo_i),
	.mem_whilo	(mem_whilo_i)
);
//==========//=====\\==========//
//==========|| MEM ||==========//
//==========\\=====//==========//
mem mem0(
	.rst(rst),
	//===== INPUT EX/MEM =====//
	.wd_i		(mem_wd_i),
	.wreg_i		(mem_wreg_i),
	.wdata_i	(mem_wdata_i),
	.hi_i		(mem_hi_i),
	.lo_i		(mem_lo_i),
	.whilo_i	(mem_whilo_i),
	//===== OUTPUT MEM/WB =====//
	.wd_o		(mem_wd_o),
	.wreg_o		(mem_wreg_o),
	.wdata_o	(mem_wdata_o),
	.hi_o		(mem_hi_o),
	.lo_o		(mem_lo_o),
	.whilo_o	(mem_whilo_o)
);
//==========//========\\==========//
//==========|| MEM/WB ||==========//
//==========\\========//==========//
mem_wb mem_wb0(
	.clk(clk), .rst(rst),
	//===== INPUT MEM =====//
	.mem_wd		(mem_wd_o),
	.mem_wreg	(mem_wreg_o),
	.mem_wdata	(mem_wdata_o),
	.mem_hi		(mem_hi_o),
	.mem_lo		(mem_lo_o),
	.mem_whilo	(mem_whilo_o),
	//===== OUTPUT REG =====//
	.wb_wd		(wb_wd_i),
	.wb_wreg	(wb_wreg_i),
	.wb_wdata	(wb_wdata_i),
	.wb_hi		(wb_hi_i),
	.wb_lo		(wb_lo_i),
	.wb_whilo	(wb_whilo_i)
);
//==========//=====\\==========//
//==========|| REG ||==========//
//==========\\=====//==========//
regfile regfile1(
	.clk (clk), .rst (rst),
	//===== ID -> REG =====//
	.re1 		(reg1_read),
	.raddr1 	(reg1_addr),
	.re2 		(reg2_read),
	.raddr2 	(reg2_addr),
	//===== MEM/WB -> REG =====//
	.we			(wb_wreg_i),
	.waddr 		(wb_wd_i),
	.wdata 		(wb_wdata_i),
	//===== REG -> ID =====//
	.rdata1 	(reg1_data),
	.rdata2 	(reg2_data)
);
//==========//======\\==========//
//==========|| HILO ||==========//
//==========\\======//==========//
hilo_reg hilo_reg0(
	.clk(clk), .rst(rst),
	//===== INPUT MEM/WB =====//
	.we		(wb_whilo_i),
	.hi_i	(wb_hi_i),
	.lo_i	(wb_lo_i),
	//===== OUTPUT EX =====//
	.hi_o	(hi),
	.lo_o	(lo)	
);
endmodule