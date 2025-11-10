`include "mux_select.vh"

module cpu_mux (
    input wire [7:0] mux_data_a_i,
    input wire [7:0] mux_data_b_i,
    input wire [7:0] mux_y_i,
    input wire [7:0] mux_pc_i,
    input wire [4:0] mux_data_op_i,
    input wire [2:0] mux_select_i,
    output reg [7:0] mux_data_o
);

always @(*) begin
    case (mux_select_i)
        `MUX_SELECT_REG_A: mux_data_o = mux_data_a_i;
        `MUX_SELECT_REG_B: mux_data_o = mux_data_b_i;
        `MUX_SELECT_OP: mux_data_o = {3'b000, mux_data_op_i};
        `MUX_SELECT_ALU_Y: mux_data_o = mux_y_i;
        `MUX_SELECT_PC: mux_data_o = mux_pc_i;
        `MUX_SELECT_NONE: mux_data_o = 8'd0;
        default: mux_data_o = 8'd0;
    endcase
end
endmodule