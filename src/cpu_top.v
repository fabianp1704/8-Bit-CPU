module cpu_top (
    input wire [7:0] in,
    output wire [7:0] out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire clk_i,
    input wire rst_ni
);

    assign uio_oe = 8'b00001111;
    assign uio_out[7:4] = 4'b0000;


    wire [7:0] reg_a;
    wire [7:0] reg_b;
    wire [4:0] reg_op;
    wire [2:0] mux_sel;
    wire strobe_io_done, io_fsm_write_a, io_fsm_write_x;

    cpu_io_fsm io_fsm (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .fsm_start_i(in[0]),
        .fsm_bit_i(in[1]),
        .select_mux_manual_i(in[4:2]),
        .enable_mux_manual_select_i(in[5]),
        .reg_a_out(reg_a),
        .reg_b_out(reg_b),
        .reg_op_out(reg_op),
        .io_done_o(strobe_io_done),
        .write_a(io_fsm_write_a),
        .write_x(io_fsm_write_x),
        .mux_sel_o(mux_sel)
    );

    wire pc_inc;
    wire [7:0] pc_q;

    cpu_pc pc (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .inc_i(pc_inc),
        .q_o(pc_q)
    );

    wire ctrl_write_enable_a, ctrl_write_enable_x;
    wire [4:0] alu_op;
    wire [7:0] alu_y;
    wire alu_z, alu_c, alu_v, alu_n;

    cpu_ctrl_fsm ctrl_fsm (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .exec_enable_i(strobe_io_done), // only load, when io fsm is ready
        .z_i(alu_z),
        .c_i(alu_c),
        .v_i(alu_v),
        .n_i(alu_n),
        .operation_i(reg_op),
        .pc_inc_o(pc_inc),
        .alu_op_o(alu_op),
        .write_enable_a_o(ctrl_write_enable_a),
        .write_enable_x_o(ctrl_write_enable_x)
    );


    wire [7:0] reg_a_q, reg_x_q;

    //wire [7:0] reg_a_data = strobe_io_done ? reg_a : alu_y;
    //wire [7:0] reg_x_data = strobe_io_done ? reg_b : alu_y;


    //wire total_write_enable_a = ctrl_write_enable_a | strobe_io_done;
    //wire total_write_enable_x = ctrl_write_enable_x | strobe_io_done;

    wire [7:0] reg_a_data = strobe_io_done ? reg_a : alu_y;
    wire [7:0] reg_x_data = strobe_io_done ? reg_b : alu_y;
    wire total_write_enable_a = strobe_io_done ? io_fsm_write_a : ctrl_write_enable_a;
    wire total_write_enable_x = strobe_io_done ? io_fsm_write_x : ctrl_write_enable_x;



    cpu_regfile regfile (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .write_enable_a_i(total_write_enable_a),
        .write_enable_x_i(total_write_enable_x),
        .data_a_i(reg_a_data),
        .data_x_i(reg_x_data),
        .q_a_o(reg_a_q),
        .q_x_o(reg_x_q)
    );

    cpu_alu alu (
        .a_i(reg_a_q),
        .b_i(reg_x_q),
        .operation_i(alu_op),
        .y_o(alu_y),
        .z_o(alu_z),
        .c_o(alu_c),
        .v_o(alu_v),
        .n_o(alu_n)
    );

    wire [7:0] mux_out;

    cpu_mux mux (
        .mux_data_a_i(reg_a_q),
        .mux_data_b_i(reg_x_q),
        .mux_y_i(alu_y),
        .mux_pc_i(pc_q),
        .mux_data_op_i(reg_op),
        .mux_select_i(mux_sel),
        .mux_data_o(mux_out)
    );

    assign out = mux_out;
    assign uio_out[0] = alu_c;
    assign uio_out[1] = alu_z;
    assign uio_out[2] = alu_v;
    assign uio_out[3] = alu_n;

    wire _unused = &{in[7:6], uio_in, 1'b0};
endmodule