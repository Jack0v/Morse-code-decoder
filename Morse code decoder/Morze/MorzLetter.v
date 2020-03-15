module MorzL(	output [6:0]ABCDEFGY,
				output [6:0]ABCDEFGIY,
				output [1:0]LedY,
				output [1:0]StatusY,
					input aM,
						input C);
	//"-" >= 4T;
	//"." <= 3T;
	//время между элементами < 7T;
	//время между кодами >= 7T;
	
	//СЧ строба
	wire [23:0]CTStrobQ;
	wire StrobY = CTStrobQ == 24'd12_500_000;
	CT #(24) CTStrob(.Q(CTStrobQ), .INC(1'd1), .R(StrobY), .C(C));
	
	//Подавление дребезга
	wire KQ;
	Chatter Chatter(.Q(KQ), .aX(aM), .C(C));
	
	//Выявление спадающего фронта
	wire TDelayQ;
	TD TDelay(.Q(TDelayQ), .D(KQ), .C(C));
	wire FFrontY = !KQ & TDelayQ;
	
	//СЧ длительности элемента
	wire [2:0]CTLongQ;
	wire CTLongEq4Y = CTLongQ == 3'd4;
	CT #(3) CTLong(.Q(CTLongQ), .INC(KQ & !CTLongEq4Y & StrobY), .R(FFrontY), .C(C));

	//СЧ длительности интервала между кодами
	wire [2:0]CTIntervalQ;
	wire CTIntervalEq7Y = CTIntervalQ == 3'd7;
	CT #(3) CTInterval(.Q(CTIntervalQ), .INC(!KQ & !CTIntervalEq7Y & StrobY), .R(FFrontY), .C(C));
	
	//преобразователь кодов
	wire [6:0]ConverserY;
	wire [6:0]ConverserStateY;
	Converser Converser(.Y(ConverserY), .StateY(ConverserStateY), .StatusY(StatusY),
							.S(FFrontY), .M(CTLongEq4Y), .R(CTIntervalEq7Y),
								.C(C));

	assign ABCDEFGY  = ConverserY;
	assign ABCDEFGIY = ConverserStateY;
	assign LedY = KQ? (CTLongEq4Y? 2'b11 : 2'b10) : (CTIntervalEq7Y? 2'b00 : 2'b01);
	
endmodule

module Converser(	output reg [6:0]Y,
					output reg [6:0]StateY,
					output reg [1:0]StatusY,
						input S, M, R,
							input C);

	parameter 	a0 = 0, a1 = 1, a2 = 2, a3 = 3,
				a4 = 4, a5 = 5, a6 = 6, a7 = 7, a8 = 8;
	
	reg [3:0]aY;
	reg [3:0]aQ;
	always @(posedge C)
	begin
		aQ <= aY;
	end
	always @*
	begin
		case(aQ)
			a0:
			begin
				Y = 7'b0000000;
				StateY = 7'b1111110;
				StatusY = 2'b01;
				if(!S)
				begin aY = a0; end
					else
					begin
						if(S & !M) begin aY = a1; end
							else
							begin
								if(S & M) begin aY = a8; end
									else begin aY = a8; end
							end
					end
			end
			a1:
			begin
				Y = 7'b1001111;
				StateY = 7'b0110000;
				StatusY = 2'b10;
				if(!S) begin aY = a1; end
					else
					begin
						if(S & !R & !M) begin aY = a2; end
							else
							begin
								if(S & !R & M) begin aY = a5; end
									else
									begin
										if(S & R & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a2:
			begin
				Y = 7'b0110000;
				StateY = 7'b1101101;
				StatusY = 2'b10;
				if(!S) begin aY = a2; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R & !M) begin aY = a3; end
									else
									begin
										if(S & !R & M) begin aY = a6; end
											else
											begin
												if(S & R & M) begin aY = a8; end
													else begin aY = a8; end
											end
									end
							end
					end
			end
			a3:
			begin
				Y = 7'b1011011;
				StateY = 7'b1111001;
				StatusY = 2'b10;
				if(!S) begin aY = a3; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R & !M) begin aY = a4; end
									else
									begin
										if(S & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a4:
			begin
				Y = 7'b0110111;
				StateY = 7'b0110011;
				StatusY = 2'b10;
				if(!S) begin aY = a4; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R) begin aY = a8; end
									else
									begin
										if(S & R & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a5:
			begin
				Y = 7'b1110111;
				StateY = 7'b1011011;
				StatusY = 2'b10;
				if(!S) begin aY = a5; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R) begin aY = a8; end
									else
									begin
										if(S & R & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a6:
			begin
				Y = 7'b0111110;
				StateY = 7'b1011111;
				StatusY = 2'b10;
				if(!S) begin aY = a6; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R & !M) begin aY = a7; end
									else
									begin
										if(S & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a7:
			begin
				Y = 7'b1000111;
				StateY = 7'b1110000;
				StatusY = 2'b10;
				if(!S) begin aY = a7; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R) begin aY = a8; end
									else
									begin
										if(S & R & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			a8:
			begin
				Y = 7'b1001001;
				StateY = 7'b1111111;
				StatusY = 2'b11;
				if(!S) begin aY = a8; end
					else
					begin
						if(S & R & !M) begin aY = a1; end
							else
							begin
								if(S & !R) begin aY = a8; end
									else
									begin
										if(S & R & M) begin aY = a8; end
											else begin aY = a8; end
									end
							end
					end
			end
			default: begin Y = 7'b1001001; StateY = 7'b0001000; aY = a8; end
		endcase
	end
endmodule