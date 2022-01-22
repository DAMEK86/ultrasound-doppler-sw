module i2c_slave_bridge # (
        parameter FILTER_LEN = 4,
        parameter DEVICE_ADDRESS = 7'h25
)
(
        input wire      clk,
        input wire      rst,

        /*
        * I2C interface
        */
        input  wire     scl_i,
        output wire     scl_o,
        output wire     scl_t,
        input  wire     sda_i,
        output wire     sda_o,
        output wire     sda_t,

        output wire     busy,
        output wire     bus_addressed,
        output wire     bus_active,

        output [7:0] leds
);

parameter p_axilite_data_width = 8;
parameter p_axilite_addr_width = 8;
parameter mem_addr_length = 16;


reg [p_axilite_addr_width-1:0]          m_axil_awaddr;
wire [2:0]                              m_axil_awprot;
reg                                     m_axil_awvalid;
wire                                    m_axil_awready;
reg [p_axilite_data_width-1:0]         m_axil_wdata;
wire [p_axilite_data_width / 8-1:0]     m_axil_wstrb;
reg                                     m_axil_wvalid;
wire                                    m_axil_wready;
wire [1:0]                              m_axil_bresp;
wire                                    m_axil_bvalid;
wire                                    m_axil_bready;
wire [p_axilite_addr_width-1:0]         m_axil_araddr;
wire [p_axilite_addr_width-1:0]         m_axil_araddr_word;
wire [2:0]                              m_axil_arprot;
reg                                    m_axil_arvalid;
reg                                     m_axil_arvalid_z;
reg                                     m_axil_arvalid_zz;
reg                                     m_axil_arvalid_zzz;
wire                                    m_axil_arready;
reg [p_axilite_data_width-1:0]          m_axil_rdata;
wire [1:0]                              m_axil_rresp;
reg                                     m_axil_rvalid;
wire                                    m_axil_rready;

assign m_axil_awready = 1;
assign m_axil_wready = 1;
assign m_axil_arready = ~m_axil_arvalid_z;
assign m_axil_bvalid = m_axil_bready;

//assign m_axil_araddr_word = m_axil_araddr[15:2];

i2c_slave_axil_master #(
        .FILTER_LEN(FILTER_LEN),
        .DATA_WIDTH(p_axilite_data_width),  // width of data bus in bits
        .ADDR_WIDTH(p_axilite_addr_width),  // width of address bus in bits
        .STRB_WIDTH(p_axilite_data_width/8)
    ) i2c_slave_axil_master_inst (
        .clk (clk),
        .rst (rst),

        /*
        * I2C interface
        */
        .i2c_scl_i (scl_i),
        .i2c_scl_o (scl_o),
        .i2c_scl_t (scl_t),
        .i2c_sda_i (sda_i),
        .i2c_sda_o (sda_o),
        .i2c_sda_t (sda_t),

        /*
        * AXI lite master interface
        */
        .m_axil_awaddr  (m_axil_awaddr_int),
        // .m_axil_awprot  (m_axil_awprot),
        .m_axil_awvalid (m_axil_awvalid_int),
        .m_axil_awready (m_axil_awready),
        .m_axil_wdata   (m_axil_wdata_int),
        // .m_axil_wstrb   (m_axil_wstrb),
        .m_axil_wvalid  (m_axil_wvalid_int),
        .m_axil_wready  (m_axil_wready),
        .m_axil_bresp   (0),
        // .m_axil_bvalid  (m_axil_bvalid),
        .m_axil_bvalid  (m_axil_bready),
        .m_axil_bready  (m_axil_bready),
        .m_axil_araddr  (m_axil_araddr),
        // .m_axil_arprot  (m_axil_arprot),
        .m_axil_arvalid (m_axil_arvalid_int),
        .m_axil_arready (m_axil_arready),
        .m_axil_rdata   (m_axil_rdata),
        // .m_axil_rresp   (m_axil_rresp),
        .m_axil_rresp   (0),
        .m_axil_rvalid  (m_axil_rvalid),
        .m_axil_rready  (m_axil_rready),

        /*
        * Status
        */
        .busy           (busy),
        .bus_addressed  (bus_addressed),
        .bus_active     (bus_active),

        /*
        * Configuration
        */
        .enable         (1'b1),
        .device_address (DEVICE_ADDRESS)
);

always @(posedge clk or posedge rst) begin
        if (rst) begin
                m_axil_rvalid <= 0;
                m_axil_rdata <= 0;
                m_axil_arvalid_z <= 0;
                m_axil_arvalid_zz <= 0;
                m_axil_arvalid_zzz <= 0;
        end
        else begin
                m_axil_arvalid_zzz <= m_axil_arvalid_zz;
                m_axil_arvalid_zz <= m_axil_arvalid_z;
                m_axil_arvalid_z <= m_axil_arvalid;

                if(m_axil_wvalid && m_axil_awvalid) begin
                        mem[m_axil_awaddr] <= m_axil_wdata;
                end

                if (m_axil_arvalid_zzz == 1 && m_axil_arvalid_zz == 0) begin
                        m_axil_rdata <= (m_axil_araddr < mem_addr_length) ?mem[m_axil_araddr] : 0;
                        m_axil_rvalid <= 1;
                end 
                else if (m_axil_rready) begin
                        m_axil_rvalid <= 0;
                end
        end
end

wire m_axil_awvalid_int;
wire m_axil_wvalid_int;
wire m_axil_arvalid_int;
wire [p_axilite_addr_width - 1 : 0] m_axil_awaddr_int;
wire [p_axilite_data_width - 1 : 0] m_axil_wdata_int;
wire [p_axilite_addr_width - 1 : 0] m_axil_araddr_int;

always @(posedge clk or posedge rst) begin
        if (rst) begin
                m_axil_awvalid <= 1'b0;
                m_axil_wvalid  <= 1'b0;
                m_axil_arvalid <= 1'b0;
        end 
        else begin
                if (m_axil_awready & m_axil_awvalid) begin
                        m_axil_awvalid <= 1'b0;
                end 
                else if (m_axil_awvalid_int) begin
                        m_axil_awaddr <= m_axil_awaddr_int;
                        m_axil_awvalid <= 1'b1;
                end
                if (m_axil_wready && m_axil_wvalid) begin
                        m_axil_wvalid <= 1'b0;
                end 
                else if (m_axil_wvalid_int) begin
                        m_axil_wdata <= m_axil_wdata_int;
                        m_axil_wvalid <= 1'b1;
                end
                if (m_axil_arready && m_axil_arvalid) begin
                        m_axil_arvalid <= 1'b0;
                end 
                else if (m_axil_arvalid_int) begin
                        //m_axil_araddr <= m_axil_araddr_int;
                        m_axil_arvalid <= 1'b1;
                end
        end
end

reg [p_axilite_data_width-1:0] mem [0:mem_addr_length-1];

assign leds = m_axil_wdata[7:0];

endmodule
