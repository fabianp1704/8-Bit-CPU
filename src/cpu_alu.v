`include "operations.vh"

module cpu_alu (
    input wire[7:0] a_i,
    input wire[7:0] b_i,
    input wire[4:0] operation_i,
    output reg[7:0] y_o,
    output reg z_o, // zero flag
    output reg c_o, // carry flag
    output reg v_o, // overflow flag
    output reg n_o // negative flag
);

    reg [8:0] result; // 9-bit for carry (addition or subtraction)

    reg signed [7:0] a_signed;
    reg signed [7:0] b_signed;
    reg signed [7:0] result_signed;

    always @(*) begin
        // default assignments
        result = 9'd0;
        result_signed = 0;
        v_o = 1'd0;
        y_o = 8'd0;
        c_o = 1'b0;
        z_o = 1'b0;
        n_o = 1'b0;

        a_signed = a_i;
        b_signed = b_i;

        case (operation_i)
            `OP_ADD: begin 
                result = a_i + b_i;
                result_signed = a_signed + b_signed;
                v_o = (a_signed[7] == b_signed[7]) && (result_signed[7] != a_signed[7]); // overflow if same sign in a and b but different in result
            end
            `OP_SUB: begin
                result = a_i - b_i;
                result_signed = a_signed - b_signed;
                v_o = (a_signed[7] != b_signed[7]) && (result_signed[7] != a_signed[7]); // overflow if different sign in a and b and different in result
            end
            `OP_AND: result = {1'b0, a_i & b_i}; // logic and
            `OP_OR: result = {1'b0, a_i | b_i}; // logic or
            `OP_XOR: result = {1'b0, a_i ^ b_i}; // logic xor
            `OP_PASS_A, `OP_MOVE_REG_XA: result = {1'b0, a_i}; // pass through A
            `OP_PASS_B, `OP_MOVE_REG_AX: result = {1'b0, b_i}; // pass through B
            `OP_SHL_A: result = {a_i[7], a_i[6:0], 1'b0}; // left shift (LSB 0)
            `OP_SHR_A: result = {a_i[0], 1'b0, a_i[7:1]}; // right shift (MSB 0)
            `OP_INC_REG_A : begin
                result = {1'b0, a_i + 8'd1};
                c_o = (a_i == 8'd255);
            end
            `OP_DEC_REG_A : begin
                result = {1'b0, a_i - 8'd1};
                c_o = (a_i == 8'd0);
            end
            `OP_NOT_A: result = {1'b0, ~a_i}; // negate a
            `OP_NEG_A: result = {1'b0, -a_i}; // 2 complement
            `OP_CLR_A: result = 9'd0; // clear a
            `OP_MAX: result = {1'b0, (a_i > b_i) ? a_i : b_i}; // max
            `OP_MIN: result = {1'b0, (a_i < b_i) ? a_i : b_i}; // min
            `OP_ABS_A: begin // abs
                if (a_i[7] == 1'b1)
                    result = {1'b0, -a_i};
                else
                    result = {1'b0, a_i};
            end
            default: begin
                result = 9'd0;
                v_o = 1'd0;
            end
        endcase

        y_o = result[7:0];
        if (operation_i != `OP_INC_REG_A && operation_i != `OP_DEC_REG_A) begin
            c_o = result[8];
        end
        z_o = result[7:0] == 8'b00000000; // zero flag
        n_o = result[7];
    end
    wire _unused = &{result_signed[6:0], 1'b0};
endmodule