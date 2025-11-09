module cpu_register #(
    parameter WIDTH = 8
) (
    input wire clk_i,
    input wire rst_ni,
    input wire shift_i,
    input wire bit_i,
    output wire [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] data_reg;

// serial shift because of serial ports
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_reg <= {WIDTH{1'b0}};
        end else begin
            if (shift_i) begin
                data_reg <= {data_reg[WIDTH-2:0], bit_i};
            end
        end
    end

    assign data_o = data_reg;

endmodule