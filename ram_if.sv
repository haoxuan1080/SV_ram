interface ram_if #(int D_WIDTH=32, int A_WIDTH=5) (input bit clk);
	logic [D_WIDTH-1:0] write_data, read_data;
	logic [A_WIDTH-1:0] write_addr, read_addr;
	logic write_en, read_en, read_valid;
	logic rst;

	clocking cb @(posedge clk);
		output write_data, write_addr, read_addr, write_en, read_en;
		input read_data, read_valid;

	endclocking

	modport TEST(clocking cb, output rst);
	modport DUT(input write_data, write_addr, read_addr, write_en,read_en, rst, clk,
		    output read_data, read_valid);

endinterface

