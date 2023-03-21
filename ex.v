`include "define.v"

module ex(
	input	wire				rst,
	
	input	wire[`AluOpBus]  	aluop_i,
	input	wire[`AluSelBus] 	alusel_i,
	input	wire[`RegBus]    	reg1_i,
	input	wire[`RegBus]    	reg2_i,
	input	wire[`RegAddrBus]	wd_i,
	input	wire             	wreg_i,

	output	reg[`RegAddrBus]    wd_o,
	output	reg                 wreg_o,
	output	reg[`RegBus]		wdata_o,
	// HILO module
	input	wire[`RegBus]		hi_i,
	input	wire[`RegBus]		lo_i,
	// wb
	input	wire[`RegBus]		wb_hi_i,
	input	wire[`RegBus]		wb_lo_i,
	input	wire				wb_whilo_i,
	// memoey
	input	wire[`RegBus]		mem_hi_i,
	input	wire[`RegBus]		mem_lo_i,
	input	wire				mem_whilo_i,

	output	reg[`RegBus]		hi_o,
	output	reg[`RegBus]		lo_o,
	output	reg					whilo_o
);

reg [`RegBus] logicout;
reg [`RegBus] shiftres;
reg [`RegBus] moveres;
reg [`RegBus] HI;
reg [`RegBus] LO;

wire				ov_sum;			// check overflow
wire				reg1_eq_reg2;	// Is the first value equal to the second
wire				reg1_lt_reg2;	// Is the first value less than to the second
reg [`RegBus] 		arithmeticres; 	// operation
wire[`RegBus]		reg2_i_mux;		// save reg2_i complement 		
wire[`RegBus]		reg1_i_not;		// save reg1_i not
wire[`RegBus]		result_sum;		
wire[`RegBus]		opdata1_mult;	// multiplicand
wire[`RegBus]		opdata2_mult;	// multiplier
wire[`DoubleRegBus]	hilo_temp;		// wait mult result	
reg [`DoubleRegBus] mulres; 		// muit result

assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP)  ||
					 (aluop_i == `EXE_SUBU_OP) ||
					 (aluop_i == `EXE_SLT_OP)) ?
					 (~reg2_i) + 1: reg2_i;

assign result_sum = reg1_i + reg2_i_mux;

assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) || 
				((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));

assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP)? ((reg1_i[31] && !reg2_i[31]) ||
												(!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
												(reg1_i[31] && reg2_i[31] && result_sum[31]))
												: (reg1_i < reg2_i); 

assign reg1_i_not = ~reg1_i;




always @ (*) begin
	wd_o 	= wd_i;	
	if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum))
		wreg_o = `WriteDisable;
	else 	 	
		wreg_o 	= wreg_i;
end
//===== HILO =====//
always @ (*)begin
	if(rst == `RstEnable)
		{HI, LO} = {`ZeroWord, `ZeroWord};
	else if(mem_whilo_i == `WriteEnable)
		{HI, LO} = {mem_hi_i, mem_lo_i};
	else if(wb_whilo_i == `WriteEnable)
		{HI, LO} = {wb_hi_i, wb_lo_i};
	else
		{HI, LO} = {hi_i, lo_i};
end

always @ (*) begin
	if(rst == `RstEnable)	logicout = `ZeroWord;
	else begin
		case (aluop_i)
			`EXE_OR_OP:		logicout = reg1_i | reg2_i;
			`EXE_AND_OP:	logicout = reg1_i & reg2_i;
			`EXE_NOR_OP:	logicout = ~(reg1_i | reg2_i);
			`EXE_XOR_OP:	logicout = reg1_i ^ reg2_i;
			default:		logicout = `ZeroWord;
		endcase
	end    
end     

always @ (*) begin
	if(rst == `RstEnable) 	shiftres = `ZeroWord;
	else begin
		case (aluop_i)
			`EXE_SLL_OP:	shiftres = reg2_i << reg1_i[4:0];
			`EXE_SRL_OP:	shiftres = reg2_i >> reg1_i[4:0];
			`EXE_SRA_OP:	shiftres = ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
			default:		shiftres = `ZeroWord;
		endcase
	end    
end     

always @ (*)begin
	if(rst == `RstEnable)	moveres =`ZeroWord;
	else begin
		moveres = `ZeroWord;
		case(aluop_i)
			`EXE_MFHI_OP:	moveres = HI;
			`EXE_MFLO_OP:	moveres = LO;
			`EXE_MOVZ_OP:	moveres = reg1_i;
			`EXE_MOVN_OP:	moveres = reg1_i;
			default:		moveres = `ZeroWord;
		endcase
	end
end

always @ (*)begin
	if(rst == `ReadEnable)	arithmeticres = `ZeroWord;
	else begin
		case(aluop_i)
			`EXE_SLT_OP, `EXE_SLTU_OP:begin // comparison operation 
				arithmeticres = reg1_lt_reg2;
			end
			`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP,`EXE_ADDIU_OP, // add operation
			`EXE_SUB_OP, `EXE_SUBU_OP :begin		  // sub operation  
				arithmeticres = result_sum;
			end
			`EXE_CLZ_OP:begin // count operation clz
				arithmeticres = reg1_i[31]?  0: reg1_i[30]?  1:
								reg1_i[29]?  2: reg1_i[28]?  3:
								reg1_i[27]?  4: reg1_i[26]?  5:
								reg1_i[25]?  6: reg1_i[24]?  7:
								reg1_i[23]?  8: reg1_i[22]?  9:
								reg1_i[21]? 10: reg1_i[20]? 11:
								reg1_i[19]? 12: reg1_i[18]? 13:
								reg1_i[17]? 14: reg1_i[16]? 15:
								reg1_i[15]? 16: reg1_i[14]? 17:
								reg1_i[13]? 18: reg1_i[12]? 19:
								reg1_i[11]? 20: reg1_i[10]? 21:
								reg1_i[ 9]? 22: reg1_i[ 8]? 23:
								reg1_i[ 7]? 24: reg1_i[ 6]? 25:
								reg1_i[ 5]? 26: reg1_i[ 4]? 27:
								reg1_i[ 3]? 28: reg1_i[ 2]? 29:
								reg1_i[ 1]? 30: reg1_i[ 0]? 31: 32;
			end
			`EXE_CLO_OP:begin // count operation clo
				arithmeticres = reg1_i_not[31]?  0: reg1_i_not[30]?  2:
								reg1_i_not[29]?  2: reg1_i_not[28]?  3:
								reg1_i_not[27]?  4: reg1_i_not[26]?  5:
								reg1_i_not[25]?  6: reg1_i_not[24]?  7:
								reg1_i_not[23]?  8: reg1_i_not[22]?  9:
								reg1_i_not[21]? 10: reg1_i_not[20]? 11:
								reg1_i_not[19]? 12: reg1_i_not[18]? 13:
								reg1_i_not[17]? 14: reg1_i_not[16]? 15:
								reg1_i_not[15]? 16: reg1_i_not[14]? 17:
								reg1_i_not[13]? 18: reg1_i_not[12]? 19:
								reg1_i_not[11]? 20: reg1_i_not[10]? 21:
								reg1_i_not[ 9]? 22: reg1_i_not[ 8]? 23:
								reg1_i_not[ 7]? 24: reg1_i_not[ 6]? 25:
								reg1_i_not[ 5]? 26: reg1_i_not[ 4]? 27:
								reg1_i_not[ 3]? 28: reg1_i_not[ 2]? 29:
								reg1_i_not[ 1]? 30: reg1_i_not[ 0]? 31: 32;
			end
			default:
				arithmeticres = `ZeroWord;
		endcase
	end
end
//===== mul =====//
assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) && (reg1_i[31]))? (~reg1_i + 1): reg1_i;
assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) && (reg2_i[31]))? (~reg2_i + 1): reg2_i;
assign hilo_temp = opdata1_mult * opdata2_mult;

always @ (*) begin
	if(rst == `ZeroWord) mulres = {`ZeroWord, `ZeroWord};
	else begin
		if((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))begin
			if(reg1_i[31] ^ reg2_i[31])
				mulres = ~hilo_temp + 1;
			else 
				mulres = hilo_temp;
		end
		else
			mulres = hilo_temp;
	end
end


always @ (*) begin
	case (alusel_i) 
	`EXE_RES_LOGIC:			wdata_o = logicout;
	`EXE_RES_SHIFT:			wdata_o = shiftres;
	`EXE_RES_MOVE:			wdata_o = moveres;
	`EXE_RES_ARITHMETIC:	wdata_o = arithmeticres;
	`EXE_RES_MUL:			wdata_o = mulres[31:0];
	default:				wdata_o = `ZeroWord;
	endcase
end	

always @ (*)begin
	if(rst == `RstEnable)begin
		whilo_o	= `WriteDisable;
		hi_o	= `ZeroWord;
		lo_o	= `ZeroWord;
	end
	else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP))begin
		whilo_o	= `WriteEnable;
		hi_o	= mulres[63:32];
		lo_o	= mulres[31:0];
	end
	else if(aluop_i == `EXE_MTHI_OP)begin
		whilo_o	= `WriteEnable;
		hi_o	= reg1_i;
		lo_o	= LO;
	end
	else if(aluop_i == `EXE_MTLO_OP)begin
		whilo_o	= `WriteEnable;
		hi_o	= HI;
		lo_o	= reg1_i;
	end
	else begin
		whilo_o	= `WriteDisable;
		hi_o	= `ZeroWord;
		lo_o	= `ZeroWord;
	end
end

endmodule