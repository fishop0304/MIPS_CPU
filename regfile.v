`include "define.v"

module regfile(
	input	wire				clk,
	input	wire				rst,
	
	input	wire				we,
	input 	wire[`RegAddrBus]	waddr,
	input 	wire[`RegBus]		wdata,
	
	input 	wire				re1,
	input 	wire[`RegAddrBus]	raddr1,
	output 	reg[`RegBus]		rdata1,
	
	input 	wire				re2,
	input 	wire[`RegAddrBus]	raddr2,
	output	reg[`RegBus]		rdata2
);

reg[`RegBus]  regs[0:`RegNum-1];
integer i;

always @ (posedge clk) begin
	if (rst == `RstDisable) begin
		if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
			regs[waddr] <= wdata;
		end
	end
	else begin
		for(i = 0; i < `RegNum; i = i + 1)
			regs[i] <= `RegWidth'h0;
	end
end

always @ (*) begin
	//===========================================================//
	//=== radd1 read addr, waddr write addr, wdata write data ===//
	//===========================================================//
	if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))
		rdata1 = wdata;
	else if(re1 == `ReadEnable)
		rdata1 = regs[raddr1];
	else
		rdata1 = `ZeroWord;

	// if(rst == `RstEnable) 
	// 	rdata1 <= `ZeroWord;
	// else if(raddr1 == `RegNumLog2'h0)
	// 	rdata1 <= `ZeroWord;
	// else if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))
	// 	rdata1 <= wdata;
	// else if(re1 == `ReadEnable)
	// 	rdata1 <= regs[raddr1];
	// else
	// 	rdata1 <= `ZeroWord;
end

always @ (*) begin
	if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))
		rdata2 = wdata;
	else if(re2 == `ReadEnable)
		rdata2 = regs[raddr2];
	else
		rdata2 = `ZeroWord;

	// if(rst == `RstEnable)
	// 		rdata2 <= `ZeroWord;
	// else if(raddr2 == `RegNumLog2'h0)
	// 	rdata2 <= `ZeroWord;
	// else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))
	// 	rdata2 <= wdata;
	// else if(re2 == `ReadEnable)
	// 	rdata2 <= regs[raddr2];
	// else
	// 	rdata2 <= `ZeroWord;
end

endmodule