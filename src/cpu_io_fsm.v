`include "mux_select.vh"
`include "states.vh"
`include "operations.vh"

module cpu_io_fsm (
    input wire clk_i,
    input wire rst_ni,

    input wire fsm_start_i,
    input wire fsm_bit_i, // fsm_bit_i: serial input bit for loading register A, B, or operation

    input wire[2:0] select_mux_manual_i,
    input wire enable_mux_manual_select_i,

    output wire[7:0] reg_a_out,
    output wire[7:0] reg_b_out,
    output wire[3:0] reg_op_out,

    output wire io_done_o,
    output reg write_a,
    output reg write_x,


    output wire [2:0] mux_sel_o
);

    reg [2:0] state;
    reg [2:0] next_state;
    reg [3:0] count;

    wire [7:0] data_a;
    wire [7:0] data_b;
    wire [3:0] data_op;

    reg [2:0] select_mux_fsm;

    assign mux_sel_o = enable_mux_manual_select_i ? select_mux_manual_i : select_mux_fsm;

    cpu_register #(.WIDTH(8)) reg_a (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .shift_i(state == `ST_LOAD_A),
        .bit_i(fsm_bit_i),
        .data_o(data_a)
    );

    cpu_register #(.WIDTH(8)) reg_b (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .shift_i(state == `ST_LOAD_B),
        .bit_i(fsm_bit_i),
        .data_o(data_b)
    );

    cpu_register #(.WIDTH(4)) reg_op (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .shift_i(state == `ST_LOAD_OP),
        .bit_i(fsm_bit_i),
        .data_o(data_op)
    );


    assign reg_a_out = data_a;
    assign reg_b_out = data_b;
    assign reg_op_out = data_op;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            state <= `ST_IDLE;
        else
            state <= next_state;
    end

    reg io_done_q;
    reg io_done_o_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            io_done_o_d <= 1'b0;
            io_done_q   <= 1'b0;
        end else begin
            io_done_o_d <= (state == `ST_DONE_OP) && !io_done_q;
            io_done_q   <= (state == `ST_DONE_OP);
        end
    end

    assign io_done_o = io_done_o_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 4'd0;
            select_mux_fsm <= `MUX_SELECT_NONE;
        end else begin
            write_a <= 1'b0;
            write_x <= 1'b0;

            case (state)
                `ST_IDLE: begin
                    count <= 4'd0;
                    select_mux_fsm <= `MUX_SELECT_ALU_Y;
                end
                `ST_LOAD_A: begin
                    count <= count + 1;
                    select_mux_fsm <= `MUX_SELECT_REG_A;
                end
                `ST_DONE_A: begin
                    count <= 4'd0;
                    select_mux_fsm <= `MUX_SELECT_REG_A;
                end
                `ST_LOAD_B: begin
                    count <= count + 1;
                    select_mux_fsm <= `MUX_SELECT_REG_B;
                end
                `ST_DONE_B: begin
                    count <= 4'd0;
                    select_mux_fsm <= `MUX_SELECT_REG_B;
                end
                `ST_LOAD_OP: begin
                    count <= count + 1;
                    select_mux_fsm <= `MUX_SELECT_OP;
                end
                `ST_DONE_OP: begin
                    count <= 4'd0;
                    select_mux_fsm <= `MUX_SELECT_OP;

                    case (data_op)
                        `OP_ADD, `OP_SUB, `OP_AND, `OP_OR, `OP_XOR: begin
                            write_a <= 1'b1; // A := reg_a_out
                            write_x <= 1'b1; // X := reg_b_out
                        end
                        `OP_INC_REG_A, `OP_DEC_REG_A, `OP_SHL_A, `OP_SHR_A, `OP_PASS_A: begin
                            write_a <= 1'b1;
                        end
                        `OP_PASS_B: begin
                            write_x <= 1'b1;
                        end

                        `OP_MOVE_REG_AX: begin
                            write_x <= 1'b1;
                        end
                        `OP_MOVE_REG_XA: begin
                            write_a <= 1'b1;
                        end
                        default: ;
                    endcase
                end
                default: begin
                    count <= 4'd0;
                    select_mux_fsm <= `MUX_SELECT_NONE;
                end
            endcase
        end
    end

    always @(*) begin

        next_state = state;

        case (state)
            `ST_IDLE: begin
                if (fsm_start_i) begin
                    next_state = `ST_LOAD_A;
                end
            end
            `ST_LOAD_A: begin
                if (count == 4'd7) begin
                    next_state = `ST_DONE_A;
                end            
            end
            `ST_DONE_A: begin
                next_state = `ST_LOAD_B;
            end
            `ST_LOAD_B: begin
                if (count == 4'd7) begin
                    next_state = `ST_DONE_B;
                end
            end
            `ST_DONE_B: begin
                next_state = `ST_LOAD_OP;
            end
            `ST_LOAD_OP: begin
                if (count == 4'd3) begin
                    next_state = `ST_DONE_OP;
                end
            end
            `ST_DONE_OP: begin
                next_state = `ST_IDLE;
            end
            default: begin
                next_state = `ST_IDLE;
            end
        endcase
    end
endmodule