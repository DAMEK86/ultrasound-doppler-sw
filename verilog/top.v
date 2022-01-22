`include "modules/i2c-slave.v"
`include "modules/i2c-slave-axil-master.v"
`include "modules/i2c-slave-bridge.v"
module top(
        input           ref_12mhz,
	inout           i2c_sda,
        inout           i2c_scl,
//        input           rst,
        output [7:0]    leds
);

reg rst;

initial begin
        rst = 1'b0;
        rst = 1'b1;
        rst = 1'b0;
end

wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_scl_t;
wire i2c_scl_tn = ~i2c_scl_t;
wire i2c_sda_i;
wire i2c_sda_o;
wire i2c_sda_t;
wire i2c_sda_tn = ~i2c_sda_t;

// i2c buffers
SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
) i2cPins [1:0](
        .PACKAGE_PIN({i2c_scl, i2c_sda}),
        .OUTPUT_ENABLE({i2c_scl_tn, i2c_sda_tn}),
        .D_OUT_0({i2c_scl_o, i2c_sda_o}),
        .D_IN_0({i2c_scl_i, i2c_sda_i})
);

i2c_slave_bridge #(
        .FILTER_LEN(4),
        .DEVICE_ADDRESS(7'h55)
) i2c_bridge55(
        .clk(ref_12mhz),
        .rst(rst),

        /*
        * I2C interface
        */
        .scl_i(i2c_scl_i),
        .scl_o(i2c_scl_o),
        .scl_t(i2c_scl_t),
        .sda_i(i2c_sda_i),
        .sda_o(i2c_sda_o),
        .sda_t(i2c_sda_t),

        .busy(),
        .bus_addressed(),
        .bus_active(),
        
        .leds(leds)
);
 
endmodule