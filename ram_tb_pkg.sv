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

    class Transaction #(D_WIDTH=8, A_WIDTH=5);
        rand bit [A_WIDTH-1: 0] addr;
        rand bit [D_WIDTH-1: 0] data;
        rand bit                wr;

        function void print(string tag="");
            $display ("T=%0t, [%s] write=0x%0h address=0x%0h, data=0x%0h", $time, tag, wr, addr, data);
        endfunction 
    endclass

    function bit Tr_equal(input Transaction tr_1, tr_2);
        if ((tr_1.addr == tr_2.addr) && (tr_1.data == tr_2.data) && (tr_1.wr == tr_2.wr)) begin
            return 1'b1;
        end
        else begin
            return 1'b0;
        end
    endfunction

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

    class Agent;
        mailbox #(Transaction) from_generator, to_driver, to_scoreboard;
        Transaction tr;

        function new(input mailbox #(Transaction) from_generator, to_driver, to_scoreboard);
            this.from_generator = from_generator;
            this.to_driver = to_driver;
            this.to_scoreboard = to_scoreboard;
        endfunction

        task run();
            forever begin
                from_generator.get(tr);
                //processing if needed
                to_driver.put(tr);
                to_scoreboard.put(tr.copy());

            end
        endtask
    endclass
    
    class scoreboard #(D_WIDTH=8, A_WIDTH=5);
        typedef bit [D_WIDTH-1:0] ram_unit;
        typedef bit [A_WIDTH-1:0] ram_addr;

        mailbox #(Transaction) from_agent;
        mailbox #(Transaction) to_checker;
        Transaction tr;

        ram_unit expected_data[ram_addr] = '{default: {D_WIDTH{'h0}}};

        function new(input mailbox #(Transaction) from_agent, to_checker);
            this.from_agent = from_agent;
            this.to_checker = to_checker;
        endfunction

        task run();
            forever begin
                from_agent.get(tr);
                if (tr.wr) begin
                    expected_data[tr.addr] = tr.data;
                end
                else begin
                    tr.data = expected_data[tr.addr];
                    to_checker.put(tr);
                end
            end
        endtask
    endclass

    class Checker; 
        mailbox #(Transaction) from_scoreboard, from_monitor;
        Transaction tr_1, tr_2;
        
        function new(input mailbox #(Transaction) from_scoreboard, from_monitor);
            this.from_scoreboard = from_scoreboard;
            this.from_monitor = from_monitor;
        endfunction

        task automatic run();
        //question: should I use automatic here?
            int i = 0;
            forever begin
                from_scoreboard.get(tr_1);
                from_monitor.get(tr_2);
                if (!Tr_equal(tr_1, tr_2)) begin
                    $display("T=%0t, [Checker] Transaction %d not same: expected: wr=0x%0h address=0x%0h, data=0x%0h", $time, i, tr_1.wr, tr_1.addr, tr_1.data);
                    $display("T=%0t, [Checker] Transaction %d not same: observed: wr=0x%0h address=0x%0h, data=0x%0h", $time, i, tr_2.wr, tr_2.addr, tr_2.data);
                end
                else begin
                    $display("T=%0t, [Checker] Transaction %d check successful!", $time, i);
                end
                i++;
            end
        endtask
    endclass

    class driver #(D_WIDTH=8, A_WIDTH=5);
        virtual ram_if ramif;
        mailbox #(Transaction) from_agent;
        Transaction tr;
        
        function new(input mailbox #(Transaction) from_agent, virtual ram_if ramif);
            this.ramif = ramif;
            this.from_agent = from_agent;
        endfunction

        virtual task run();
            ramif.cb.write_data <= {D_WIDTH{'h0}};
            ramif.cb.write_addr <= {A_WIDTH{'h0}};
            ramif.cb.read_addr <= {A_WIDTH{'h0}};
            ramif.cb.write_en <= 1'b0;
            ramif.cb.read_en <= 1'b0;
            @ramif.cb
            forever begin
                from_agent.get(tr);
                if (tr.wr) begin
                    ramif.write_data <= tr.data;
                    ramif.write_addr <= tr.addr;
                    ramif.write_en <= 1'b1;

                    @ramif.cb
                    ramif.write_en <= 1'b0;
                end
                else begin
                    ramif.read_addr <= tr.addr;
                    ramif.read_en <= 1'b1;
                    @ramif.cb
                    ramif.wread_en <= 1'b0;
                end
            end
        endtask
    endclass

    class monitor #(D_WIDTH=8, A_WIDTH=5);
        virtual ram_if ramif;
        mailbox #(Transaction) to_checker;
        Transaction tr;
        bit [A_WIDTH-1:0] address_buffer [0:1];

        function new(input mailbox #(Transaction) to_checker, virtual ram_if ramif);
            this.ramif = ramif;
            this.to_checker = to_checker;
        endfunction

        virtual task run();
            forever begin
                address_buffer[0] <= ramif.cb.read_address;
                address_buffer[1] <= address_buffer[0];
                @ramif.cb
                if (ramif.cb.read_valid) begin
                    tr = new();
                    tr.wr = 1'b0;
                    tr.addr = address_buffer[1]; 
                    tr.addr = ramif.cb.read_data;
                    to_checker.put(tr);
                end
            end
        endtask
    endclass
    
    class env #(D_WIDTH=8, A_WIDTH=5);
        virtual ram_if ramif;
        mailbox #(Transaction) gen_2_agt, agt_2_scb, agt_2_drv, scb_2_ckr, mon_2_ckr;
        driver #(D_WIDTH, A_WIDTH) drv;
        monitor #(D_WIDTH, A_WIDTH) mon;
        generator gen;
        scoreboard #(D_WIDTH, A_WIDTH) scb;
        Agent agt;
        Checker ckr;
        
        function new(virtual ram_if ramif);
            gen = new(gen_2_agt);
            agt = new(gen_2_agt, agt_2_drv, agt_2_scb);
            scb = new(agt_2_scb, scb_2_ckr);
            ckr = new(scb_2_ckr, mon_2_ckr);
            drv = new(agt_2_drv, ramif);
            mon = new(mon_2_ckr, ramif);            
        endfunction
    
        task run(int num_itr=10);
            fork
                gen.run(num_itr);
                agt.run();
                scb.run();
                ckr.run();
                drv.run();
                mon.run();
            join
        endtask
        
    endclass

endpackage


