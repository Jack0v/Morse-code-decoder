/*
Autor: Jack0v
Morse code decoder, digits only.
Source video: https://youtu.be/wNrg9gkYU_I
	!!!WARNING!!!
	This project was tested for EP4CE6E22C8 by QurtusII 9.1SP2.
	Before compiling, specify the pins of the your FPGA. Example:
	//(*chip_pin = "11"*) input aM
*/
/*
Автор: Jack0v
Декодер кодов азбуки Морзе, только цифры.
Исходное видео: https://youtu.be/wNrg9gkYU_I
	!!!ВНИМАНИЕ!!!
	Этот проект тестировался под EP4CE6E22C8 в QurtusII 9.1SP2.
	Перед компиляцией укажи выводы своей ПЛИС. Пример:
	//(*chip_pin = "11"*) input aM
*/
//(C) Jack0v, 2020
module Morz((*chip_pin = "00, 00, 00, 00,  00,  00,  00"*) output reg [6:0]nABCDEFGY,
			(*chip_pin = "00, 00, 00, 00,  00,  00,  00"*) output [6:0]nABCDEFGIY,
			(*altera_attribute = "-name VIRTUAL_PIN ON"*) output [1:0]StatusY,
				(*chip_pin = "00"*) input aM,
					(*chip_pin = "00"*) input C);
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
	CT #(3) CTInterval(.Q(CTIntervalQ), .INC(!KQ & !CTIntervalEq7Y & StrobY), .R(KQ), .C(C));
	
	//Выявление нарастающего фронта
	wire RFrontY = KQ & !TDelayQ;
	
	//СЧ битов
	wire [2:0]CTBitQ;
	wire INC_CTBit = FFrontY & (CTBitQ != 3'd5);
	CT #(3) CTBit(.Q(CTBitQ), .INC(INC_CTBit), .R(RFrontY & CTIntervalEq7Y), .C(C));
	
	//РЕГ битов
	wire [4:0]REGBitQ;
	REGSH REGBit(.Q(REGBitQ), .SH(INC_CTBit), .D(CTLongEq4Y), .C(C));
	// _____
	//|	 a	|
	//|f	|b
	//|		|
	//|_____|
	//|	 g	|
	//|e	|c
	//|		|
	//|_____|
	//	 d
	reg ErrorY;
	always @(*)
	begin
		if(CTBitQ == 3'd5)
		begin
			case(REGBitQ)
				5'b11111:	begin			  //abcdefg
								ErrorY = 0;
								nABCDEFGY = ~7'b1111110; //0
							end
				5'b01111:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b0110000; //1
							end
				5'b00111:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1101101; //2
							end
				5'b00011:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1111001; //3
							end
				5'b00001:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b0110011; //4
							end
				5'b00000:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1011011; //5
							end
				5'b10000:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1011111; //6
							end
				5'b11000:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1110000; //7
							end
				5'b11100:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1111111; //8
							end
				5'b11110:	begin
								ErrorY = 0;
								nABCDEFGY = ~7'b1111011; //9
							end
				default:	begin
								ErrorY = 1'd1;
								nABCDEFGY = ~7'b1001111; //ошибка
							end
			endcase
		end	else
			begin
				ErrorY = 0;
				nABCDEFGY = ~7'd0;
			end
	end
	
	assign nABCDEFGIY = ~(KQ? (CTLongEq4Y? 7'b0110000 : 7'b1111110) : (CTIntervalEq7Y? 7'b0000000 : 7'b0000001));
	
	// StatusY:
	// 00 - в процессе;
	// 01 - простаивание;
	// 10 - результат;
	// 11 - ошибка;
	assign StatusY = {CTBitQ == 3'd5, (CTBitQ == 3'd5)? ErrorY : CTIntervalEq7Y};
endmodule

module Chatter(output reg Q, input aX, input C);
	reg X;
	reg [15:0]CTQ;
	always @(posedge C)
	begin
		X <= aX;
		if(X & ~&CTQ) begin CTQ <= CTQ + 1'd1; end
			else
			begin
				if(!X & |CTQ) begin CTQ <= CTQ - 1'd1; end
			end
		if(&CTQ) begin Q <= 1'd1; end
			else
			begin
				if(~|CTQ) begin Q <= 0; end
			end
	end
endmodule

module TD (output reg Q, input D, input C);
	always @(posedge C) begin Q <= D; end
endmodule

module CT #(parameter N = 3) (output reg [N-1:0]Q, input INC, input R, input C);
	always @(posedge C)
	begin
		if(R) begin Q <= 0; end
			else
			begin
				if(INC) begin Q <= Q + 1'd1; end
			end
	end
endmodule

module REGSH(output reg [4:0]Q, input SH, D, input C);
	always @(posedge C)
	begin
		if(SH) begin Q <= {Q[3:0], D}; end
	end
endmodule