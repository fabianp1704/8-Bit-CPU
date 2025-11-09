`timescale 1ns/1ps
`include "operations.vh"
`include "mux_select.vh"
`include "states.vh"

`include "cpu_alu.v"
`include "cpu_ctrl_fsm.v"
`include "cpu_io_fsm.v"
`include "cpu_mux.v"
`include "cpu_pc.v"
`include "cpu_regfile.v"
`include "cpu_register.v"
`include "cpu_top.v"
`include "tt_um_cpu_fabianp1704.v"


module tb ();

    parameter CLK_PERIOD = 20;

    reg clk_tb;
    reg rst_tb;
    reg [7:0] in_tb;
    wire [7:0] out_tb;
    reg [7:0] uio_in_tb;
    wire [7:0] uio_out_tb;
    wire [7:0] uio_oe_tb;

    tt_um_cpu_fabianp1704 uut (
        .ui_in (in_tb),
        .uo_out (out_tb),
        .uio_in (uio_in_tb),
        .uio_out (uio_out_tb),
        .uio_oe (uio_oe_tb),
        .ena (1'b1),
        .clk (clk_tb),
        .rst_n (rst_tb)
    );

    initial begin
        clk_tb = 0;
        in_tb = 8'd0;
        uio_in_tb = 8'd0;

        rst_tb = 0;
        #(2*CLK_PERIOD);
        rst_tb = 1;
        #(2*CLK_PERIOD);
    end
    always #(CLK_PERIOD/2) begin
        clk_tb = ~clk_tb;
    end

    task task_reset;
        begin
            rst_tb = 0;
            #(2*CLK_PERIOD);
            rst_tb = 1;
            #(2*CLK_PERIOD);
        end
    endtask

    task task_serial_shift;
        input [7:0] val;
        input integer len;
        integer i;
        begin
            for (i = len-1; i >= 0; i=i-1) begin
                @(negedge clk_tb);
                in_tb[1] = val[i];
                @(posedge clk_tb);
            end
            @(negedge clk_tb);
            in_tb[1] = 1'b0;
        end
    endtask

    task run_test;
        input [7:0] a_val;
        input [7:0] b_val;
        input [3:0] op_val;
        input [127:0] name;
        begin
            task_reset();
            $display("Test: %s", name);
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(a_val, 8); // a
            task_serial_shift(b_val, 8); // b
            task_serial_shift(op_val, 4); // operation
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            $display("A=%0d B=%0d OP=%0d  =>  OUT=%0d (binary: %0b)", a_val, b_val, op_val, out_tb, out_tb);
            $display("Flags: C=%b Z=%b V=%b N=%b\n", uio_out_tb[0], uio_out_tb[1], uio_out_tb[2], uio_out_tb[3]);
            #(3*CLK_PERIOD);
        end
    endtask

    task run_test_mux_manual;
        input [7:0] a_val;
        input [7:0] b_val;
        input [3:0] op;
        input [127:0] name; 
        begin
            task_reset();
            $display("Test: %s", name);
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(a_val, 8); // a
            task_serial_shift(b_val, 8); // b
            task_serial_shift(op, 4); // operation
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);

            in_tb[5] = 1'b1;
            #(2*CLK_PERIOD);

            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_REG_A: out = %0d; expected = %0d", out_tb, a_val);
            #(2*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_REG_B: out = %0d; expected = 0 (no writing in regfile X when op=PASS_A)", out_tb);
            #(2*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_ALU_Y;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_ALU_Y: out = %0d", out_tb);
            #(2*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_OP;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_OP: out = %0d; expected = %0d", out_tb, op);
            #(2*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_PC;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_PC: out = %0d", out_tb);
            #(2*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_NONE;
            #(2*CLK_PERIOD);
            $display("MUX_SELECT_NONE: out = %0d", out_tb);
            #(2*CLK_PERIOD);

            in_tb[5] = 1'b0;
            #(3*CLK_PERIOD);
        end
    endtask

    task run_test_multiple_operations;
        begin
            task_reset();
            $display("Test: Multiple operations");

            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd10, 8);
            task_serial_shift(8'd5, 8);
            task_serial_shift(`OP_ADD, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            $display("ADD: out = %0d (expected=15)", out_tb);

            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd10, 8);
            task_serial_shift(8'd5, 8);
            task_serial_shift(`OP_SUB, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            $display("SUB: out = %0d (expected=5)", out_tb);

            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd6, 8);
            task_serial_shift(8'd3, 8);
            task_serial_shift(`OP_XOR, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            $display("XOR: out = %0d (expected=5)", out_tb);
            #(3*CLK_PERIOD);
        end
    endtask

    task run_test_rst_bhv;
        begin
            $display("Test: reset (output should be zero)");
            task_reset();   
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd100, 8);
            task_serial_shift(8'd50, 8);
            task_serial_shift(`OP_ADD, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);

            $display("Output before rst = %0d (%0b)", out_tb, out_tb);

            in_tb[5] = 1'b1;
            in_tb[4:2] = `MUX_SELECT_PC;
            #(CLK_PERIOD);
            $display("Program Counter before rst = %0d", out_tb);
            #(CLK_PERIOD);

            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(CLK_PERIOD);
            $display("RegA before rst = %0d", out_tb);

            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(CLK_PERIOD);
            $display("RegX before rst = %0d", out_tb);
            in_tb[5] = 1'b0;

            rst_tb = 0;
            #(2*CLK_PERIOD);
            rst_tb = 1;
            #(5*CLK_PERIOD);

            $display("Output after rst = %0b", out_tb);

            in_tb[5] = 1'b1;
            in_tb[4:2] = `MUX_SELECT_PC;
            #(CLK_PERIOD);
            $display("Program Counter after rst = %0b", out_tb);
            #(CLK_PERIOD);

            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(CLK_PERIOD);
            $display("RegA after rst = %0d", out_tb);

            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(CLK_PERIOD);
            $display("RegX after rst = %0d", out_tb);
            in_tb[5] = 1'b0;

            in_tb[5] = 1'b1;
            in_tb[4:2] = `MUX_SELECT_PC;
            #(CLK_PERIOD);
            $display("Program Counter after rst = %0b", out_tb);
            in_tb[5] = 1'b0;
            #(3*CLK_PERIOD);
        end
    endtask

        task run_test_regfile;
        begin
            $display("Test: Register File");

            task_reset();

            // write reg A and X
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd12, 8);   // A = 12
            task_serial_shift(8'd34, 8);   // X = 34
            task_serial_shift(`OP_PASS_A, 4); // pass a chosen because its a "neutral" operation
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd12, 8);   // A = 12
            task_serial_shift(8'd34, 8);   // X = 34
            task_serial_shift(`OP_PASS_B, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);
            $display("Loaded A=12, X=34 (check PASS A and PASS B)");

            // manual MUX select to read A and X
            in_tb[5] = 1'b1; // enable manual mux
            #CLK_PERIOD;

            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(2*CLK_PERIOD);
            $display("MUX A output: %0d (expected 12)", out_tb);

            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(2*CLK_PERIOD);
            $display("MUX X output: %0d (expected 34)", out_tb);

            // now move A to X and check again
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd12, 8);   // A
            task_serial_shift(8'd34, 8);   // X
            task_serial_shift(`OP_MOVE_REG_XA, 4); // X := A
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);

            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(CLK_PERIOD);
            $display("After MOVE A to X, X=%0d (expected 12)", out_tb);
            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(CLK_PERIOD);
            $display("After MOVE A to X, A=%0d (expected 12 so should stay the same)", out_tb);

            // overwrite A, keep X
            @(negedge clk_tb);
            in_tb[0] = 1'b1; // Start FSM
            @(posedge clk_tb);
            in_tb[0] = 1'b0;
            task_serial_shift(8'd77, 8);
            task_serial_shift(8'd0, 8);
            task_serial_shift(`OP_PASS_A, 4);
            @(posedge clk_tb);
            @(posedge clk_tb);
            @(posedge clk_tb);

            in_tb[4:2] = `MUX_SELECT_REG_A;
            #(CLK_PERIOD);
            $display("A overwritten: A=%0d (expected 77)", out_tb);
            #(3*CLK_PERIOD);
            in_tb[4:2] = `MUX_SELECT_REG_B;
            #(CLK_PERIOD);
            $display("X should stay the same: X=%0d (expected 12)", out_tb);

            in_tb[5] = 0;
            #(3*CLK_PERIOD);
        end
    endtask

    initial begin

        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // test reset bhv


        run_test_rst_bhv();


        // test alu operations
        run_test(8'd11, 8'd15, 4'd0, "Test 1: ADD");
        run_test(8'd127, 8'd1, 4'd0, "Test 1.1: ADD (overflow)");
        run_test(8'd255, 8'd1, 4'd0, "Test 1.2: ADD (carry)");
        run_test(8'd200, 8'd150, 4'd1, "Test 2: SUB");
        run_test(8'd0, 8'd1, 4'd1, "Test 2.1: SUB (borrow)");
        run_test(8'd6, 8'd9, 4'd2, "Test 3: AND");
        run_test(8'd6, 8'd9, 4'd3, "Test 4: OR");
        run_test(8'd6, 8'd9, 4'd4, "Test 5: XOR");
        run_test(8'd11, 8'd15, 4'd5, "Test 6: PASS A");
        run_test(8'd11, 8'd15, 4'd6, "Test 7: PASS B");
        run_test(8'd11, 8'd15, 4'd7, "Test 8: SHL A");
        run_test(8'd128, 8'd0, 4'd7, "Test 8.1: SHL A (carry)");
        run_test(8'd11, 8'd15, 4'd8, "Test 9: SHR A");
        run_test(8'd1, 8'd0, 4'd8, "Test 9.1: SHR A (carry)");
        run_test(8'd11, 8'd15, 4'd9, "Test 10: MOVE XA");
        run_test(8'd11, 8'd15, 4'd10, "Test 11: MOVE AX");
        run_test(8'd11, 8'd0, 4'd11, "Test 12: INC A");
        run_test(8'd255, 8'd0, 4'd11, "Test 12.1: INC A");
        run_test(8'd11, 8'd0, 4'd12, "Test 13: DEC A");
        run_test(8'd0, 8'd0, 4'd12, "Test 13.1: DEC A");

        // test multiple operations after another
        run_test_multiple_operations();

        // test manual mux output
        run_test_mux_manual(8'd11, 8'd3, 4'd5, "Test MUX (with PASS A)");

        // test regfile
        run_test_regfile();
        
        $display("\n All tests completed");
        $finish;

    end
endmodule