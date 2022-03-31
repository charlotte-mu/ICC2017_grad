/******************************************************************/
//MODULE:       DT
//FILE NAME:    DT.v
//VERSION:		1.0
//DATE:			June,2018
//AUTHOR: 		charlotte-mu
//CODE TYPE:	RTL
//DESCRIPTION:	2017 IC Design Contest Preliminary
//
//MODIFICATION HISTORY:
// VERSION Date Description
// 1.0 06/07/2018 test pattern all pass
/******************************************************************/
module DT(
	input 			clk, 
	input				reset,
	output reg		done ,
	output reg		sti_rd ,
	output reg[9:0]sti_addr ,
	input	[15:0]	sti_di,
	output reg		res_wr ,
	output reg		res_rd ,
	output reg[13:0]res_addr ,
	output reg[7:0]res_do,
	input	[7:0]		res_di
	);

reg [7:0]data_reg1[127:0];
reg [7:0]data_reg2,data_reg3;
reg [4:0]conter,conter_;
reg [7:0]con;
reg en,cn,forward_en;
reg [13:0]res_addr_;
wire [0:15]sti_di_;
wire [7:0]data_min1,data_min2,data_min3;

assign sti_di_ = sti_di;
assign data_min1 = (data_reg1[(con-8'd1)] >= data_reg1[con])? data_reg1[con] : data_reg1[(con-8'd1)];
assign data_min2 = (data_reg1[(con+8'd1)] >= res_do)? res_do : data_reg1[(con+8'd1)];
assign data_min3 = (data_min1 >= data_min2)? data_min2 : data_min1;

always@(clk,reset,forward_en)
begin
	if(reset == 1'b0)
	begin
		res_wr = 1'b0;
		res_rd = 1'b0;
	end
	else
	begin
		if(forward_en == 1'b0)
		begin
			res_wr = 1'b1;
			res_rd = 1'b0;
		end
		else
		begin
			if(clk == 1'b0)
			begin
				res_wr = 1'b1;
				res_rd = 1'b0;
			end
			else
			begin
				res_wr = 1'b0;
				res_rd = 1'b1;
			end
		end
	end
end

always@(clk,reset,res_addr_,forward_en)
begin
	if(reset == 1'b0)
	begin
		res_addr = 14'd0;
	end
	else
	begin
		if(forward_en == 1'b0)
		begin
			res_addr = res_addr_;
		end
		else
		begin
			if(clk == 1'b1)
			begin
				res_addr = res_addr_- 14'd1;
			end
			else
			begin
				res_addr = res_addr_;
			end
		end
	end
end

always@(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
	begin
		sti_addr <= 10'd0;
		sti_rd <= 1'b0;
		//res_wr <= 1'b0;
		conter <= 4'd0;
		conter_ <= 4'd0;
		con <= 8'd0;
		en <= 1'b0;
		cn <= 1'b0;
		forward_en <= 1'b0;
	end
	else
	begin
		if(forward_en == 1'b0)
		begin
			if(en == 1'b0)
			begin
				sti_rd <= 1'b1;
				sti_addr <= 10'd0;
				done <= 1'b0;
				en <= 1'b1;
				//res_wr <= 1'b1;
				res_addr_ <= 14'd0;
			end
			else
			begin
				if(res_addr == 14'd16383)
				begin
					forward_en <= 1'b1;
					conter <= 5'd15;
					conter_ <= 5'd0;
					con <= 8'd127;
					cn <= 1'b0;
				end
				else
				begin
					if(conter == 5'd15)
					begin
						conter <= 5'd0;
						if(sti_addr < 10'd1023)
							sti_addr <= sti_addr + 10'd1;
					end
					else
					begin
						conter <= conter + 4'd1;
					end
					//
					if(con > 8'd126)
						con <= 8'd0;
					else
						con <= con + 8'd1;
					//
					if(cn == 1'b0)
						cn <= 1'b1;
					else
					begin
						//
						if(conter_ == 5'd15)
						begin
							conter_ <= 5'd0;
						end
						else
						begin
							conter_ <= conter_ + 4'd1;
						end
						//
						res_addr_ <= res_addr_ + 14'd1;
					end
				end
			end
		end
		else//---------------------------
		begin
			//res_rd <= 1'b1;
			//res_wr <= 1'b0;
			if(conter == 5'd0)
			begin
				conter <= 5'd15;
				sti_addr <= sti_addr - 10'd1;
			end
			else
			begin
				conter <= conter - 4'd1;
			end
			//
			if(con == 8'd0)
				con <= 8'd127;
			else
				con <= con - 8'd1;
			//
			if(conter_ == 5'd0)
				conter_ <= 5'd15;
			else
				conter_ <= conter_ - 4'd1;
			//
			//res_addr <= res_addr - 14'd1;
			if(res_addr == 14'd0)
			begin
				done <= 1'b1;
			end
			if(cn == 1'b0)
				cn <= 1'b1;
			else
				res_addr_ <= res_addr_ - 14'd1;
		end
	end
end

always@(negedge clk,negedge reset)
begin
	if(reset == 1'b0)
	begin
		//res_rd <= 1'b0;
		res_do <= 8'd0;
	end
	else
	begin
		if(forward_en == 1'b0)
		begin
			if(en == 1'b1)
			begin
				if(sti_di_[conter_] == 1'b0)
					res_do <= 8'd0;
				else
					res_do <= data_min3 +	8'd1;
				//
				if(con == 8'd0)
					data_reg1[126] <= data_reg2;
				else if(con >= 8'd2)
					data_reg1[(con-8'd2)] <= data_reg2;
				//
				data_reg2 <= res_do;
				data_reg1[127] <= 8'd0;
				data_reg1[0] <= 8'd0;
				//
			end
		end
		else//---------------------------------------
		begin
			//res_wr <= 1'b1;
			//res_rd <= 1'b0;
			if(sti_di_[conter_] == 1'b0)
				res_do <= 8'd0;
			else
			begin
				if(res_di >= (data_min3+8'd1))
					res_do <= (data_min3+8'd1);
				else
					res_do <= res_di;
			end
			//
			if(con == 8'd127)
				data_reg1[1] <= data_reg2;
			else if(con <= 8'd125)
				data_reg1[(con+8'd2)] <= data_reg2;
			//
			data_reg2 <= res_do;
			data_reg1[127] <= 8'd0;
			data_reg1[0] <= 8'd0;
			//
		end
	end
end

endmodule
