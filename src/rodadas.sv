module rodadas(
	input logic [31:0] a, b, c, d, x, s, t,
	input logic [1:0] e,
	input logic PCLK_IN,
	output logic [31:0] output_A
  );

	logic [31:0] aa;

	always_ff @ (negedge PCLK_IN)
		case(e)
			2'b00: begin
				aa <= ((a + (((b) & (c)) | ((~b) & (d))) + x + t) << s) | ((a + (((b) & (c)) | ((~b) & (d))) + x + t) >> (6'd32 - s));

			end
			2'b01: begin
				aa <= ((a + (((b) & (d)) | ((c) & (~d))) + x + t) << s) | ((a + (((b) & (d)) | ((c) & (~d))) + x + t) >> (6'd32 - s));

			end
			2'b10: begin
				aa <= ((a + ((b) ^ (c) ^ (d)) + x + t) << s) | ((a + ((b) ^ (c) ^ (d)) + x + t) >> (6'd32 - s));

			end
			2'b11: begin
				aa <= ((a + ((c) ^ ((b) | (~d))) + x + t) << s) | ((a + ((c) ^ ((b) | (~d))) + x + t) >> (6'd32 - s));

			end
		endcase

	assign output_A = aa + b;

endmodule
