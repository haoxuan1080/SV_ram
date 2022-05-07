//ram_tb_pkg.sv
package ran_tb_pkg;
    `define SV_RAND_CHECK(r) \
        do begin \
            if (!(r)) begin \
                $display ("%s:%0d: Randomization failed \"%s\"", \
                    `__FILE__, `__LINE__, `"r`"); \
                $finish; \
            end \
        end while (0)

    class Transaction #(A_WIDTH=5, D_WIDTH=8);
        rand bit [A_WIDTH-1: 0] addr;
        rand bit [D_WIDTH-1: 0] data;
        rand bit                wr;

        function void print(string tag="");
            $display ("T=%0t, [%s] write=0x%0h address=0x%0h, data=0x%0h", $time, tag, wr, addr, data);
        endfunction 
    endclass

    class generator;
        mailbox #(Transaction) to_agent;
        Transaction tr;
        
        function new(input mailbox #(Transaction) to_agent);
            this.to_agent = to_agent;
            tr = new();
        endfunction

        virtual task run(input int num_tr = 10);
            repeat (num_tr) begin
                `SV_RAND_CHECK(tr.randomize());
                to_agent.put(tr.copt());
            end
                
        endtask
    endclass

endpackage


