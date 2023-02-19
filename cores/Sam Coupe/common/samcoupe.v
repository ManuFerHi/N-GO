`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    03:54:40 13/25/2015 
// Design Name:    SAM Coup clone
// Module Name:    samcoupe
// Project Name:   SAM Coup clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module samcoupe (
    input wire clk48,
    input wire clk24,
    input wire clk12,
    input wire clk6,
    input wire clk8,
    input wire master_reset_n,
    // Video output
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b,
    output wire bright,
    output wire hsync_pal,
    output wire vsync_pal,
    // Audio output
    input wire ear,
    output wire audio_out_left,
    output wire audio_out_right,
    // PS/2 keyoard interface
    input wire clkps2,
    input wire dataps2,
    // PS/2 mouse interface
    inout wire mousedata,
    inout wire mouseclk,
    // SRAM interface
    output wire [18:0] sram_addr,
    inout wire [7:0] sram_data,
    output wire sram_we_n,
    output wire REBOOT,

    input wire[7:0] disk_data_in,
    output wire[7:0] disk_data_out,
    output wire[31:0] disk_sr,
    input wire[31:0] disk_cr,
    input wire disk_data_clkout,
    input wire disk_data_clkin,
    input wire[1:0] disk_wp,
    output wire testled,
    output wire scanlines_tg,
    output wire scandbl_tg,
    output wire joysplitter_tg,
    input wire[4:0] joystick1,
    input wire[4:0] joystick2);
    
    // ROM memory
    wire [14:0] romaddr;
    wire [7:0] data_from_rom;
    
    // RAM memory
    wire [18:0] vramaddr, cpuramaddr;
    wire [7:0] data_from_ram;
    wire [7:0] data_to_asic;
    wire ram_we_n;
    wire asic_is_using_ram;
    
    // Keyboard
    wire [8:0] kbrows;
    wire [7:0] kbcolumns;

    wire kb_nmi_n;
    wire kb_rst_n;
    wire kb_mrst_n;
    wire rdmsel;
    assign kbrows = {rdmsel, cpuaddr[15:8]};
    
    // CPU signals
    wire mreq_n, iorq_n, rd_n, wr_n, int_n, wait_n, rfsh_n, m1_n;
    wire [15:0] cpuaddr;
    wire [7:0] data_from_cpu;
    wire [7:0] data_to_cpu;
    
    // ASIC signals
    wire [7:0] data_from_asic;
    wire asic_oe_n;
    wire rom_oe_n;
    
    // ROM signals
    assign romaddr = {cpuaddr[15], cpuaddr[13:0]};
    
    // RAM signals
    wire ram_oe_n;
    
    // Audio signals
    wire mic, beep;
    wire [7:0] saa_out_l, saa_out_r;

    // disk signals
    wire[7:0] wd1770_dout;
    wire[7:0] wd1770_dout2;
    wire disk1_n;
    wire disk2_n;
    wire disk1_oe = !disk1_n && !rd_n;
    wire disk2_oe = !disk2_n && !rd_n;
    
    // MUX from memory/devices to Z80 data bus
    assign data_to_cpu = (disk2_oe == 1'b1)? wd1770_dout2 : 
                         (disk1_oe == 1'b1)? wd1770_dout :
                         (rom_oe_n == 1'b0)?  data_from_rom :
                         (ram_oe_n == 1'b0)?  data_from_ram :
                         (asic_oe_n == 1'b0)? data_from_asic :
                         8'hFF;

    tv80a el_z80 (
      .m1_n(m1_n),
      .mreq_n(mreq_n),
      .iorq_n(iorq_n),
      .rd_n(rd_n),
      .wr_n(wr_n),
      .rfsh_n(rfsh_n),
      .halt_n(),
      .busak_n(),
      .A(cpuaddr),
      .dout(data_from_cpu),

      .reset_n(kb_rst_n & master_reset_n),
      .clk(clk6),
      .wait_n(wait_n),
      .int_n(int_n),
      .nmi_n(kb_nmi_n),
      .busrq_n(1'b1),
      .di(data_to_cpu)
    );
    
    asic la_ula_del_sam (
        .clk(clk12),
        .rst_n(kb_rst_n & master_reset_n),
        // CPU interface
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .cpuaddr(cpuaddr),
        .data_from_cpu(data_from_cpu),
        .data_to_cpu(data_from_asic),
        .data_enable_n(asic_oe_n),
        .wait_n(wait_n),
        // RAM/ROM interface
        .vramaddr(vramaddr),
        .cpuramaddr(cpuramaddr),
        .data_from_ram(data_to_asic),
        .ramwr_n(ram_we_n),
        .romcs_n(rom_oe_n),
        .ramcs_n(ram_oe_n),
        .asic_is_using_ram(asic_is_using_ram),
        // audio I/O
        .ear(ear),
        .mic(mic),
        .beep(beep),
        // keyboard I/O
        .keyboard(kbcolumns),
        .rdmsel(rdmsel),
        // disk I/O
        .disc1_n(disk1_n),
        .disc2_n(disk2_n),
        // video output
        .r(r),
        .g(g),
        .b(b),
        .bright(bright),
        .hsync_pal(hsync_pal),
        .vsync_pal(vsync_pal),
        .int_n(int_n)
    );
 
    rom rom_32k (
        .clk(clk24),
        .a(romaddr),
        .dout(data_from_rom)
    );
    
    ram_dual_port_turnos ram_512k (
        .clk(clk48),
        .whichturn(asic_is_using_ram),
        .vramaddr(vramaddr),
        .cpuramaddr(cpuramaddr),
        .cpu_we_n(ram_we_n),
        .data_from_cpu(data_from_cpu),
        .data_to_asic(data_to_asic),
        .data_to_cpu(data_from_ram),
        // Actual interface with SRAM
        .sram_a(sram_addr),
        .sram_we_n(sram_we_n),
        .sram_d(sram_data)
    );

    wire [7:0] kbcolumns_k;
		wire [3:0] kbcolumns_m;
		assign kbcolumns[7:0] = cpuaddr[15:8] == 8'hff 	? {kbcolumns_k[7:4], kbcolumns_k[3:0] & kbcolumns_m[3:0]}
																										: kbcolumns_k[7:0];

    wire[7:0] scancode;
    wire scancode_valid;
		ps2 ps2_keyb(
      .kbd_clk(clkps2),
      .kbd_data(dataps2),
      .kbd_key(scancode),
      .kbd_key_valid(scancode_valid),
      .clk(clk48)
      );
      
    scancode_to_sam scan_inst(
      .scan_received(scancode_valid),
      .scan(scancode),
      .sam_row(kbrows),
      .sam_col(kbcolumns_k),
      .user_reset(kb_rst_n),
      .master_reset(kb_mrst_n),
      .user_nmi(kb_nmi_n),
      .scanlines_tg(scanlines_tg),
      .scandbl_tg(scandbl_tg),
      .joysplitter_tg(joysplitter_tg),
      .joystick1(~joystick1),
      .joystick2(~joystick2)
    );

    wire read_port_254 = iorq_n == 1'b0 && rd_n == 1'b0 && cpuaddr[7:0] == 8'hfe;
    wire read_mouse = read_port_254 && cpuaddr[15:8] == 8'hFF;
    
    ps2_mouse el_raton(
        .clk(clk12),
        .clkps2(mouseclk),
        .dataps2(mousedata),
        .mdata(kbcolumns_m),
        .rdmsel(read_mouse),
        .rstn(kb_rst_n & master_reset_n)
		);
		
    saa1099s el_saa (
        .clk_sys(clk48),  // 8 MHz
        .ce(clk8),  // 8 MHz
        .rst_n(kb_rst_n),
        .cs_n(~(cpuaddr[7:0] == 8'hFF && iorq_n == 1'b0)),
        .a0(cpuaddr[8]),  // 0=data, 1=address
        .wr_n(wr_n),
        .din(data_from_cpu),
        .out_l(saa_out_l),
        .out_r(saa_out_r)
    );
    
    mixer sam_audio_mixer (
        .clk(clk8),
        .rst_n(kb_rst_n),
        .ear(ear),
        .mic(mic),
        .spk(beep),
        .saa_left(saa_out_l),
        .saa_right(saa_out_r),
        .audio_left(audio_out_left),
        .audio_right(audio_out_right)
	);
    
    diskdrives #(.NR_DISK(2), .SHARED_FDC(1)) diskdrives_inst(
			.disk1_n(disk1_n),
			.disk2_n(disk2_n),

			.disk_data_in(disk_data_in),
			.disk_data_out(disk_data_out),
			.disk_sr(disk_sr),
			.disk_cr(disk_cr),
			.disk_data_clkout(disk_data_clkout),
			.disk_data_clkin(disk_data_clkin),
			.disk_wp(disk_wp),
			
			.cpuaddr(cpuaddr),
			.rd_n(rd_n),
			.wr_n(wr_n),
			.data_from_cpu(data_from_cpu),
			.wd1770_dout(wd1770_dout),
			.wd1770_dout2(wd1770_dout2),
			.rstn(kb_rst_n & master_reset_n),
			.clk12(clk12),
			.clk24(clk24)
		);
		
    multiboot back_to_bios (
        .clk_icap(clk24),   // WARNING: this clock must not be greater than 20MHz (50ns period)
        .mrst_n(kb_mrst_n)
    );
endmodule
