`include "operations.vh"

module cpu_ctrl_fsm (
    input wire clk_i,
    input wire rst_ni,

    input wire exec_enable_i,

    input wire z_i,
    input wire c_i,
    input wire v_i,
    input wire n_i,
    input wire [4:0] operation_i,

    output reg pc_inc_o,
    output reg [4:0] alu_op_o,
    output reg write_enable_a_o,
    output reg write_enable_x_o
);


    localparam ST_FETCH = 2'b00;
    localparam ST_EXEC = 2'b01;
    reg [1:0] state, next_state;


    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            state <= ST_FETCH;
        else
            state <= next_state;
    end

    reg exec_enable_d;
    wire start_pulse;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            exec_enable_d <= 1'b0;
        else
            exec_enable_d <= exec_enable_i;
    end

    assign start_pulse = exec_enable_i & ~exec_enable_d;

    always @(*) begin
        // default
        pc_inc_o = 1'b0;
        alu_op_o = 5'b0;
        write_enable_a_o = 1'b0;
        write_enable_x_o = 1'b0;
        next_state = state;

        case (state)
            ST_FETCH: begin
                if (start_pulse) begin
                    pc_inc_o = 1'b1;
                    next_state = ST_EXEC;
                end
            end
            ST_EXEC: begin
                alu_op_o = operation_i;
                case (operation_i)
                    `OP_ADD, `OP_SUB, `OP_AND, `OP_OR, `OP_XOR, `OP_SHL_A, `OP_SHR_A,
                    `OP_INC_REG_A, `OP_DEC_REG_A, `OP_NOT_A, `OP_NEG_A, `OP_CLR_A, `OP_ABS_A, `OP_MAX, `OP_MIN: begin
                        write_enable_a_o = 1'b1;
                    end
                    `OP_PASS_A, `OP_PASS_B: begin
                        // no writing in PASS operations
                    end
                    `OP_MOVE_REG_AX: begin
                        write_enable_a_o = 1'b1;
                    end
                    `OP_MOVE_REG_XA: begin
                        write_enable_x_o = 1'b1;
                    end
                    default: begin
                        alu_op_o = 5'd0;
                    end
                endcase
                next_state = ST_FETCH;
            end
            default: begin
                next_state = ST_FETCH;
            end
        endcase
    end
    wire _unused = &{z_i, c_i, v_i, n_i, 1'b0};
endmodule