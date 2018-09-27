`include "rodadas.sv"

module md5(
	input  logic  PCLK_IN,           // clock
		           PRESETn_IN,        // reset
		           PSEL_IN,           // seleciona o escravo
		           PENABLE_IN,        // 0 = preenche o registrador; 1 = Inicia as rodadas
		           PWRITE_IN,         // 1 = escrever; 0 = ler
	input  logic  [04:0] PADDR_IN,   // Endereço
	input  logic  [31:0] PWDATA_IN,  // Entrada de dados
	output [31:0] PRDATA_OUT,        // Sainda de dados
	output PREADY_OUT
);

	logic [2:0] APB;
	const logic [2:0] IDLE = 2'd0;
	const logic [2:0] SETUP = 2'd1;
	const logic [2:0] ACCESS = 2'd2;

   logic [31:0]PRDATA[19:0];  // Registrador das palavras
   logic [31:0]S[15:0];		   // Constante S
   logic [31:0]T[63:0];		   // Constante T

   logic [31:0] XX, SS, TT, RR,
					 MA, MB, MC, MD;
	logic [01:0] EE;

	/**************
	 * CONTADORES *
	 **************/
   logic [0:03]j;     // SS
   logic [0:03]k;     // XX
   logic [0:01]c;     // EE
	logic [0:31]CONS;  // TT


	rodadas rod(
		 .a(MA), .b(MB), .c(MC), .d(MD),
		 .x(XX), .s(SS), .t(TT), .e(EE),
		 .PCLK_IN(PCLK_IN),
		 .output_A(RR)
	);

	function [31:0] changeEndian;
		input [31:0] value;
		changeEndian = {value[7:0], value[15:8], value[23:16], value[31:24]};
	endfunction

	always @(negedge PRESETn_IN or posedge PCLK_IN) begin
		if (!PRESETn_IN) begin
			S[4'd00] <= 32'd07;
			S[4'd01] <= 32'd12;
			S[4'd02] <= 32'd17;
			S[4'd03] <= 32'd22;
			S[4'd04] <= 32'd05;
			S[4'd05] <= 32'd09;
			S[4'd06] <= 32'd14;
			S[4'd07] <= 32'd20;
			S[4'd08] <= 32'd04;
			S[4'd09] <= 32'd11;
			S[4'd10] <= 32'd16;
			S[4'd11] <= 32'd23;
			S[4'd12] <= 32'd06;
			S[4'd13] <= 32'd10;
			S[4'd14] <= 32'd15;
			S[4'd15] <= 32'd21;

			T[6'd00] <= 32'hd76aa478;
			T[6'd01] <= 32'he8c7b756;
			T[6'd02] <= 32'h242070db;
			T[6'd03] <= 32'hc1bdceee;
			T[6'd04] <= 32'hf57c0faf;
			T[6'd05] <= 32'h4787c62a;
			T[6'd06] <= 32'ha8304613;
			T[6'd07] <= 32'hfd469501;
			T[6'd08] <= 32'h698098d8;
			T[6'd09] <= 32'h8b44f7af;
			T[6'd10] <= 32'hffff5bb1;
			T[6'd11] <= 32'h895cd7be;
			T[6'd12] <= 32'h6b901122;
			T[6'd13] <= 32'hfd987193;
			T[6'd14] <= 32'ha679438e;
			T[6'd15] <= 32'h49b40821;
			T[6'd16] <= 32'hf61e2562;
			T[6'd17] <= 32'hc040b340;
			T[6'd18] <= 32'h265e5a51;
			T[6'd19] <= 32'he9b6c7aa;
			T[6'd20] <= 32'hd62f105d;
			T[6'd21] <= 32'h02441453;
			T[6'd22] <= 32'hd8a1e681;
			T[6'd23] <= 32'he7d3fbc8;
			T[6'd24] <= 32'h21e1cde6;
			T[6'd25] <= 32'hc33707d6;
			T[6'd26] <= 32'hf4d50d87;
			T[6'd27] <= 32'h455a14ed;
			T[6'd28] <= 32'ha9e3e905;
			T[6'd29] <= 32'hfcefa3f8;
			T[6'd30] <= 32'h676f02d9;
			T[6'd31] <= 32'h8d2a4c8a;
			T[6'd32] <= 32'hfffa3942;
			T[6'd33] <= 32'h8771f681;
			T[6'd34] <= 32'h6d9d6122;
			T[6'd35] <= 32'hfde5380c;
			T[6'd36] <= 32'ha4beea44;
			T[6'd37] <= 32'h4bdecfa9;
			T[6'd38] <= 32'hf6bb4b60;
			T[6'd39] <= 32'hbebfbc70;
			T[6'd40] <= 32'h289b7ec6;
			T[6'd41] <= 32'heaa127fa;
			T[6'd42] <= 32'hd4ef3085;
			T[6'd43] <= 32'h04881d05;
			T[6'd44] <= 32'hd9d4d039;
			T[6'd45] <= 32'he6db99e5;
			T[6'd46] <= 32'h1fa27cf8;
			T[6'd47] <= 32'hc4ac5665;
			T[6'd48] <= 32'hf4292244;
			T[6'd49] <= 32'h432aff97;
			T[6'd50] <= 32'hab9423a7;
			T[6'd51] <= 32'hfc93a039;
			T[6'd52] <= 32'h655b59c3;
			T[6'd53] <= 32'h8f0ccc92;
			T[6'd54] <= 32'hffeff47d;
			T[6'd55] <= 32'h85845dd1;
			T[6'd56] <= 32'h6fa87e4f;
			T[6'd57] <= 32'hfe2ce6e0;
			T[6'd58] <= 32'ha3014314;
			T[6'd59] <= 32'h4e0811a1;
			T[6'd60] <= 32'hf7537e82;
			T[6'd61] <= 32'hbd3af235;
			T[6'd62] <= 32'h2ad7d2bb;
			T[6'd63] <= 32'heb86d391;

			for(int i = 4'h0; i <= 4'h0f; i++) PRDATA[i] <= 32'h0;

			PRDATA[5'h10] <= 32'h67452301;
			PRDATA[5'h11] <= 32'hefcdab89;
			PRDATA[5'h12] <= 32'h98badcfe;
			PRDATA[5'h13] <= 32'h10325476;

			j <= 4'b0;
			k <= 4'b0;
			c <= 2'b0;
			CONS <= 6'b0;
			PREADY_OUT <= 1'd0;
			APB <= IDLE;
		end

		else begin
			case (APB)
				IDLE : begin
					if (PSEL_IN && !PENABLE_IN)
						APB <= SETUP;

				end
				SETUP : begin
					if(PENABLE_IN)
						APB <= ACCESS;
					else
						if (PWRITE_IN)
							if((PADDR_IN >= 5'h00) && (PADDR_IN <= 5'h0f))
								PRDATA[PADDR_IN] <= PWDATA_IN;

							else
								if( (PADDR_IN >= 5'h00) && (PADDR_IN <= 5'h13))
									PRDATA_OUT <= PRDATA[PADDR_IN];

								else
									PRDATA_OUT <= 32'hz;
				end
				ACCESS : begin

					/**********************************
					 * TRANSFORMACAO DO BLOCO EM HASH *
					 **********************************/
					if(CONS <= 64) begin

						if(CONS == 0) begin
							MA = PRDATA[5'h10];
							MB = PRDATA[5'h11];
							MC = PRDATA[5'h12];
							MD = PRDATA[5'h13];
						end
						else begin
							MA = MD;
							MD = MC;
							MC = MB;
							MB = RR;
						end

						XX = changeEndian(PRDATA[k]);
						SS = S[j];
						TT = T[CONS];
						EE = c;

						/******************************
						 * CONTROLADOR DAS CONSTANTES *
						 ******************************/
						if((CONS <= 11) && (j == 4'd3 )) j <= 4'd0;
						else if((CONS <= 27) && (j == 4'd07 )) j <= 4'd04;
						else if((CONS <= 43) && (j == 4'd11 )) j <= 4'd08;
						else if((CONS <= 59) && (j == 4'd15 )) j <= 4'd12;
						else j <= j + 1'b1;

						if(CONS < 15) k <= k + 1'b1;
						else if(CONS == 15) begin
							k <= 4'd1;
							c <= c + 1'b1;
						end
						else if(CONS <= 30) k <= k + 4'b0101;
						else if(CONS == 31) begin
							k <= 4'd5;
							c <= c + 1'b1;
						end
						else if(CONS <= 46) k <= k + 4'b0011;
						else if(CONS == 47) begin
							k <= 4'd0;
							c <= c + 1'b1;
						end
						else if(CONS <= 63) k <= k + 4'b0111;
						else k <= 0;

						CONS <= CONS + 6'b1;
						PRDATA_OUT <= 32'b1;

					end
					else if(CONS == 65) begin

                  PRDATA[5'h10] <= changeEndian(PRDATA[5'h10] + MA);
                  PRDATA[5'h11] <= changeEndian(PRDATA[5'h11] + MB);
                  PRDATA[5'h12] <= changeEndian(PRDATA[5'h12] + MC);
                  PRDATA[5'h13] <= changeEndian(PRDATA[5'h13] + MD);

						CONS <= CONS + 6'b1;
						PREADY_OUT <= 1'd1;
					end
				end
			endcase
		end
	end

endmodule
