//ram_tb_pkg.sv
package ran_tb_pkg;
	class Transaction #(A_WIDTH=5, D_WIDTH=8);
	rand bit [A_WIDTH-1: 0] addr;
	rand bit [D_WIDTH-1: 0] data;
	rand bit				wr;

	function void print(string tag="");
		$display ("T=%0t, [%s] write=0x%0h address=0x%0h, data=0x%0h", $time, tag, wr, addr, data)
	endfunction	
	endclass

endpackage


