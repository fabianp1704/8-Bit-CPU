module cpu_regfile (
    input wire clk_i,
    input wire rst_ni,
    input wire write_enable_a_i,
    input wire write_enable_x_i,
    input wire [7:0] data_a_i,
    input wire [7:0] data_x_i,
    output reg [7:0] q_a_o,
    output reg [7:0] q_x_o
);

always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        q_a_o <= 8'd0;
        q_x_o <= 8'd0;
    end else begin
        if (write_enable_a_i) begin
            q_a_o <= data_a_i;
        end
        if (write_enable_x_i) begin
            q_x_o <= data_x_i;
        end
    end
end
endmodule