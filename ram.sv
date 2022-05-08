
module ram (ram_if ramif);
    reg [ramif.D_WIDTH-1:0] mem [0:2**ramif.A_WIDTH-1] = '{default :0};

    always @(posedge ramif.clk or ramif.rst) begin
	    ramif.read_data <= {ramif.D_WIDTH{1'b0}};
        ramif.read_valid <= 1'b0;
		if (ramif.write_en) begin
			mem[ramif.write_addr] <= ramif.write_data;
		end

		if (ramif.rst) begin
			ramif.read_data <= {ramif.D_WIDTH{1'b0}};
		end
		else if (ramif.read_en) begin
			ramif.read_data <= mem[ramif.read_addr];
            ramif.read_valid <= 1'b1;
		end
	end

endmodule


				
