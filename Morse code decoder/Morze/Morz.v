/*
Autor: Jack0v
Morse code decoder, digits and letters A, E, F, H, I, S, U.
Source video: https://youtu.be/wNrg9gkYU_I
	!!!WARNING!!!
	This project was tested for EP4CE6E22C8 by QurtusII 9.1SP2.
	Before compiling, specify the pins of the your FPGA. Example:
	//(*chip_pin = "11"*) input aM
*/
/*
Автор: Jack0v
Декодер кодов азбуки Морзе, цифры и буквы A, E, F, H, I, S, U.
Исходное видео: https://youtu.be/wNrg9gkYU_I
	!!!ВНИМАНИЕ!!!
	Этот проект тестировался под EP4CE6E22C8 в QurtusII 9.1SP2.
	Перед компиляцией укажи выводы своей ПЛИС. Пример:
	//(*chip_pin = "11"*) input aM
*/
//(C) Jack0v, 2020
module Morz((*chip_pin = "00, 00, 00, 00,  00,  00,  00"*) output [6:0]nABCDEFGIY,
			(*chip_pin = "00, 00, 00, 00,  00,  00,  00"*) output reg [6:0]nABCDEFGY,
			(*chip_pin = "00, 00"*) output [1:0]nLedY,
				(*chip_pin = "00"*) input aM,
					(*chip_pin = "00"*) input C);



	wire [6:0]MorzDABCDEFGY;
	wire [1:0]MorzDStatusY;
	MorzD MorzD(.ABCDEFGIY(), .ABCDEFGY(MorzDABCDEFGY), .StatusY(MorzDStatusY),
				.aM(aM),
					.C(C));

	
	wire [6:0]MorzLABCDEFGY;
	wire [6:0]MorzLABCDEFGIY;
	wire [1:0]MorzLLedY;
	wire [1:0]MorzLStatusY;
	MorzL MorzL(.ABCDEFGIY(MorzLABCDEFGIY), .ABCDEFGY(MorzLABCDEFGY), .LedY(MorzLLedY), .StatusY(MorzLStatusY),
				.aM(aM),
					.C(C));
				
	assign nABCDEFGIY = ~MorzLABCDEFGIY;
	assign nLedY = ~MorzLLedY;
	
	always @*
	begin
		casex({MorzLStatusY, MorzDStatusY})
			4'b00xx: begin nABCDEFGY = ~7'b0110110;		end
			4'b0100: begin nABCDEFGY = ~7'b0000001;		end
			4'b0101: begin nABCDEFGY = ~MorzLABCDEFGY;	end
			4'b011x: begin nABCDEFGY = ~MorzDABCDEFGY;	end
			
			4'b100x: begin nABCDEFGY = ~MorzLABCDEFGY;	end
			4'b1010: begin nABCDEFGY = ~7'b0110110;		end
			4'b1011: begin nABCDEFGY = ~MorzLABCDEFGY;	end
			
			4'b11xx: begin nABCDEFGY = ~MorzDABCDEFGY;	end
		endcase
	end

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