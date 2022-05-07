`timescale 1ns/100ps

module ram_tb;
	
	import "DPI-C" function int test_bench_helper(input longint time_int, output hold_clk);
	logic clk=0;
	logic hold_clk;
	
	ram_if #(32, 5) ramif (clk);

	ram dut (ramif.DUT);
	test testing (ramif.TEST, hold_clk);



	always begin
		#10 clk = ~ clk;
		if (hold_clk) begin
			$display("received hold clock");
			$stop;
		end
	end


endmodule

module test(ram_if ramif, output logic hold_clk);
	longint time_i;
	initial begin
		ramif.rst = 1'b0;
		hold_clk = 1'b0;
		ramif.cb.write_en <= 1'b0;
		ramif.cb.read_en <= 1'b0;

		#1 ramif.rst = 1'b1;

		#15 ramif.rst = 1'b0;

		ramif.cb.read_addr <= {ramif.A_WIDTH{'h0}};
		ramif.cb.write_addr <= {ramif.A_WIDTH{'h0}};
		ramif.cb.write_data <= {ramif.D_WIDTH{'h0}};

		@ramif.cb;
		ramif.cb.write_addr <= 'h10;
		ramif.cb.write_data <= 'hff;
		ramif.cb.write_en <= 1'b1;

		@ ramif.cb;
		ramif.cb.write_addr <= {ramif.A_WIDTH{'h0}};
		ramif.cb.write_data <= {ramif.D_WIDTH{'h0}};
		ramif.cb.write_en <= 1'b0;

		@ramif.cb;
		ramif.cb.read_addr <= 'h10;
		ramif.cb.read_en <= 1'b1;

		@ramif.cb;
		ramif.cb.read_addr <= {ramif.A_WIDTH{'h0}};
		ramif.cb.read_en <= 1'b0;







	end

	always begin
		#1000;
		time_i = $stime;
		$display(time_i);

		test_bench_helper(time_i, hold_clk);
	end
endmodule
