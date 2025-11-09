/*
 * Copyright (c) 2024 Fabian Pöll
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_cpu_fabianp1704 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // instantiate the cpu
  cpu_top u_cpu (
        .in       (ui_in), // external control input
        .out      (uo_out), // 8-bit CPU output (mux_out)
        .uio_in   (uio_in), // bidirectional IO in (not in use)
        .uio_out  (uio_out), // status outputs (C,Z,V,N)
        .uio_oe   (uio_oe), // direction (low 4 bits output)
        .clk_i    (clk), 
        .rst_ni   (rst_n) 
    );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
