/*******************************************************************************
 *
 *  NetFPGA-10G http://www.netfpga.org
 *
 *  File:
 *        nf10_nic_output_port_lookup.v
 *
 *  Library:
 *        hw/std/pcores/nf10_nic_output_port_lookup_v1_00_a
 *
 *  Module:
 *        nf10_nic_output_port_lookup
 *
 *  Author:
 *        Adam Covington
 *
 *  Description:
 *        Hardwire the hardware interfaces to CPU and vice versa
 *
 *  Copyright notice:
 *        Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
 *                                 Junior University
 *
 *  Licence:
 *        This file is part of the NetFPGA 10G development base package.
 *
 *        This file is free code: you can redistribute it and/or modify it under
 *        the terms of the GNU Lesser General Public License version 2.1 as
 *        published by the Free Software Foundation.
 *
 *        This package is distributed in the hope that it will be useful, but
 *        WITHOUT ANY WARRANTY; without even the implied warranty of
 *        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *        Lesser General Public License for more details.
 *
 *        You should have received a copy of the GNU Lesser General Public
 *        License along with the NetFPGA source package.  If not, see
 *        http://www.gnu.org/licenses/.
 *
 */

module nf10_nic_output_port_lookup
#(
	parameter C_FAMILY              = "virtex5",
	parameter C_S_AXI_DATA_WIDTH    = 32,          
	parameter C_S_AXI_ADDR_WIDTH    = 32,          
	parameter C_USE_WSTRB           = 0,
	parameter C_DPHASE_TIMEOUT      = 0,
	parameter C_BASEADDR            = 32'hFFFFFFFF,
	parameter C_HIGHADDR            = 32'h00000000,
	parameter C_S_AXI_ACLK_FREQ_HZ  = 100,
    //Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter SRC_PORT_POS=16,
    parameter DST_PORT_POS=24
)
(
    // Global Ports
    input axi_aclk,
    input axi_resetn,

  // Slave AXI Ports
  input                                     S_AXI_ACLK,
  input                                     S_AXI_ARESETN,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
  input                                     S_AXI_AWVALID,
  input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
  input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
  input                                     S_AXI_WVALID,
  input                                     S_AXI_BREADY,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
  input                                     S_AXI_ARVALID,
  input                                     S_AXI_RREADY,
  output                                    S_AXI_ARREADY,
  output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
  output     [1 : 0]                        S_AXI_RRESP,
  output                                    S_AXI_RVALID,
  output                                    S_AXI_WREADY,
  output     [1 :0]                         S_AXI_BRESP,
  output                                    S_AXI_BVALID,
  output                                    S_AXI_AWREADY,

    // Master Stream Ports (interface to data path)
    output reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tstrb,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output reg m_axis_tvalid,
    input  m_axis_tready,
    output reg m_axis_tlast,

    // Slave Stream Ports (interface to RX queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input  s_axis_tvalid,
    output s_axis_tready,
    input  s_axis_tlast
);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // ---------------extra regs declaration --
    wire [C_M_AXIS_DATA_WIDTH - 1:0] fm_axis_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] fm_axis_tstrb;
    wire [C_M_AXIS_TUSER_WIDTH-1:0] fm_axis_tuser;
    wire fm_axis_tlast;
    wire fm_axis_tvalid;
    wire ack;
   // ------------ Internal Params --------
   localparam HEADER = 4'b0100;
   localparam DATA   = 4'b1000;
   localparam FIRST  = 4'b0001;
   localparam SECOND = 4'b0010;
   localparam dst_ip_reg_0 = 32'h6501A8C0;
   localparam src_ip_reg_0 = 32'h6401A8C0;
   localparam ip_checksum_reg_0 = 16'b0;
   localparam ip_proto = 8'h00;
   localparam ip_ttl = 8'h40;
   localparam ip_tos = 8'b0;
   localparam src_mac_reg_0 = 48'h112233445566;
   localparam dst_mac_reg_0 = 48'h223344556677;


  //------------- Wires ------------------
   reg [3:0] state, state_next;

   // ------------ Modules ----------------

   fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
           .MAX_DEPTH_BITS(2))
      input_fifo
        (// Outputs
         .dout                           ({fm_axis_tlast,fm_axis_tuser, fm_axis_tstrb,fm_axis_tdata}),
         .full                           (),
         .nearly_full                    (in_fifo_nearly_full),
         .prog_full                      (),
         .empty                          (in_fifo_empty),
         // Inputs
         .din                            ({s_axis_tlast, s_axis_tuser, s_axis_tstrb, s_axis_tdata}),
         .wr_en                          (s_axis_tvalid & ~in_fifo_nearly_full),
         .rd_en                          (in_fifo_rd_en),
         .reset                          (~axi_resetn),
         .clk                            (axi_aclk));

// ---------------for packet_enable generation ----

   assign packet_enable = m_axis_tlast & m_axis_tvalid & m_axis_tready;
   
// ------------- Logic ----------------

   assign s_axis_tready = !in_fifo_nearly_full;

   // modify the dst port in tuser
   always @(*) begin//{
      state_next      = state;
      m_axis_tvalid = fm_axis_tvalid;
      m_axis_tdata = fm_axis_tdata;
      m_axis_tstrb = fm_axis_tstrb;
      m_axis_tuser = fm_axis_tuser;
      m_axis_tlast = fm_axis_tlast;

      case(state)//{
        FIRST: begin//{
                m_axis_tvalid = 'b1;
                m_axis_tdata = {dst_ip_reg_0[15:0],src_ip_reg_0, ip_checksum_reg_0,ip_proto,ip_ttl,48'b0,ip_tos,8'h45,16'h0c88,src_mac_reg_0,dst_mac_reg_0};
                m_axis_tstrb = 'hffffffff;
                m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = 8'b100;
                m_axis_tlast = 'b0;
                if(m_axis_tready) begin//{
                            state_next = SECOND;
                        end//} 
                end//}

        SECOND: begin//{
                m_axis_tvalid = 'b1;
                m_axis_tdata = {240'hdeadbeefbabe ,dst_ip_reg_0[31:16]};
                m_axis_tstrb = 'hffffffff;
                m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = 8'b100;
                m_axis_tlast = 1;
                if(m_axis_tlast & m_axis_tvalid & m_axis_tready) begin//{
                           state_next = HEADER;
                         end//}
                end//}

        HEADER: if(~ack)begin//{
                        m_axis_tvalid = fm_axis_tvalid;
                        m_axis_tdata = fm_axis_tdata;
                        m_axis_tstrb = fm_axis_tstrb;
                        m_axis_tuser = fm_axis_tuser;
                        m_axis_tlast = fm_axis_tlast;
                        if(m_axis_tvalid & m_axis_tready) begin//{
                            state_next = DATA;
                        end//}
                end//}
                else    state_next= FIRST;

        DATA: begin//{
           if(m_axis_tlast & m_axis_tvalid & m_axis_tready) begin//{
              state_next = HEADER;
           end//}
        end//}

        default: state_next = HEADER;

      endcase //} case (state)
   end //} always @ (*)

   always @(posedge axi_aclk) begin
      if(~axi_resetn) begin
         state <= HEADER;
      end
      else begin
         state <= state_next;
      end
   end

   // Handle output
   assign in_fifo_rd_en = m_axis_tready && !in_fifo_empty;
   assign fm_axis_tvalid = !in_fifo_empty;



  // ---------- Regs part ----------------------------
  wire                                            Bus2IP_Clk;
  wire                                            Bus2IP_Resetn;
  wire     [C_S_AXI_ADDR_WIDTH-1 : 0]             Bus2IP_Addr;
  wire     [0:0]                                  Bus2IP_CS;
  wire                                            Bus2IP_RNW;
  wire     [C_S_AXI_DATA_WIDTH-1 : 0]             Bus2IP_Data;
  wire     [C_S_AXI_DATA_WIDTH/8-1 : 0]           Bus2IP_BE;
  wire     [C_S_AXI_DATA_WIDTH-1 : 0]             IP2Bus_Data;
  wire                                            IP2Bus_RdAck;
  wire                                            IP2Bus_WrAck;
  wire                                            IP2Bus_Error;

localparam NUM_RO_REGS       = 1;
localparam NUM_RW_REGS       = 1;


  wire     [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1 : 0] rw_regs;
  wire     [NUM_RO_REGS*C_S_AXI_DATA_WIDTH-1 : 0] ro_regs;

  // -- AXILITE IPIF
  axi_lite_ipif_1bar #
  (
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
	.C_USE_WSTRB        (C_USE_WSTRB),
	.C_DPHASE_TIMEOUT   (C_DPHASE_TIMEOUT),
   .C_BAR0_BASEADDR    (C_BASEADDR),
   .C_BAR0_HIGHADDR    (C_HIGHADDR)
  ) axi_lite_ipif_inst
  (
    .S_AXI_ACLK          ( S_AXI_ACLK     ),
    .S_AXI_ARESETN       ( S_AXI_ARESETN  ),
    .S_AXI_AWADDR        ( S_AXI_AWADDR   ),
    .S_AXI_AWVALID       ( S_AXI_AWVALID  ),
    .S_AXI_WDATA         ( S_AXI_WDATA    ),
    .S_AXI_WSTRB         ( S_AXI_WSTRB    ),
    .S_AXI_WVALID        ( S_AXI_WVALID   ),
    .S_AXI_BREADY        ( S_AXI_BREADY   ),
    .S_AXI_ARADDR        ( S_AXI_ARADDR   ),
    .S_AXI_ARVALID       ( S_AXI_ARVALID  ),
    .S_AXI_RREADY        ( S_AXI_RREADY   ),
    .S_AXI_ARREADY       ( S_AXI_ARREADY  ),
    .S_AXI_RDATA         ( S_AXI_RDATA    ),
    .S_AXI_RRESP         ( S_AXI_RRESP    ),
    .S_AXI_RVALID        ( S_AXI_RVALID   ),
    .S_AXI_WREADY        ( S_AXI_WREADY   ),
    .S_AXI_BRESP         ( S_AXI_BRESP    ),
    .S_AXI_BVALID        ( S_AXI_BVALID   ),
    .S_AXI_AWREADY       ( S_AXI_AWREADY  ),
	
	// Controls to the IP/IPIF modules
    .Bus2IP_Clk          ( Bus2IP_Clk     ),
    .Bus2IP_Resetn       ( Bus2IP_Resetn  ),
    .Bus2IP_Addr         ( Bus2IP_Addr    ),
    .Bus2IP_RNW          ( Bus2IP_RNW     ),
    .Bus2IP_BE           ( Bus2IP_BE      ),
    .Bus2IP_CS           ( Bus2IP_CS      ),
    .Bus2IP_Data         ( Bus2IP_Data    ),
    .IP2Bus_Data         ( IP2Bus_Data    ),
    .IP2Bus_WrAck        ( IP2Bus_WrAck   ),
    .IP2Bus_RdAck        ( IP2Bus_RdAck   ),
    .IP2Bus_Error        ( IP2Bus_Error   )
  );
  
  // -- IPIF REGS
  ipif_regs #
  (
    .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),          
    .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),   
    .NUM_RW_REGS        (NUM_RW_REGS),
    .NUM_RO_REGS        (NUM_RO_REGS)
  ) ipif_regs_inst
  (   
    .Bus2IP_Clk     ( Bus2IP_Clk     ),
    .Bus2IP_Resetn  ( Bus2IP_Resetn  ), 
    .Bus2IP_Addr    ( Bus2IP_Addr    ),
    .Bus2IP_CS      ( Bus2IP_CS[0]   ),
    .Bus2IP_RNW     ( Bus2IP_RNW     ),
    .Bus2IP_Data    ( Bus2IP_Data    ),
    .Bus2IP_BE      ( Bus2IP_BE      ),
    .IP2Bus_Data    ( IP2Bus_Data    ),
    .IP2Bus_RdAck   ( IP2Bus_RdAck   ),
    .IP2Bus_WrAck   ( IP2Bus_WrAck   ),
    .IP2Bus_Error   ( IP2Bus_Error   ),
	
    .rw_regs        ( rw_regs ),
    .ro_regs        ( ro_regs )
  );

wire rst_cntrs;


//localparam NUM_RW_REGS       = 5; -- update above

assign rst_cntrs = rw_regs[0];   //00
//assign enable_signal1 = rw_regs[32*1]; //04


reg  [C_S_AXI_DATA_WIDTH-1 : 0] packets;
assign ro_regs = {packets};

// LUT hit/miss counters
  always @ (posedge axi_aclk) begin
    if (~axi_resetn) begin
          packets  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end
        else if (rst_cntrs) begin
          packets  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end
        else begin
          if (packet_enable)  packets  <= packets + 1;
        end
  end

 assign ack = (packets == 'd5)? 'b1:'b0;

endmodule // output_port_lookup
