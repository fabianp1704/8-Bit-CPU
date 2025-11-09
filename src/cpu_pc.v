module cpu_pc (
    input wire clk_i,
    input wire rst_ni,
    input wire inc_i,
    output reg [7:0] q_o
);

always@(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
        q_o <= 8'd0;
    end else if (inc_i) begin
            q_o <= q_o + 8'd1;
    end
end
endmodule