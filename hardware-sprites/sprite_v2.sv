// Project F: Hardware Sprites - Sprite v2
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sprite_v2 #(
    parameter WIDTH=8,            // graphic width in pixels
    parameter HEIGHT=8,           // graphic height in pixels
    parameter SPR_FILE="",        // file to load sprite graphic from
    parameter CORDW=10,           // width of screen coordinates
    parameter H_RES_FULL=800,     // horizontal screen resolution inc. blanking
    parameter DEPTH=WIDTH*HEIGHT  // depth of memory array holding graphic
    ) (
    input  wire logic clk,               // clock
    input  wire logic rst,               // reset
    input  wire logic start,             // start control
    input  wire logic [CORDW-1:0] sx,    // horizontal screen position
    input  wire logic [CORDW-1:0] sprx,  // horizontal sprite position
    output      logic pix                // pixel colour to draw
    );

    logic memory [DEPTH];  // 1-bit per pixel

    initial begin
        if (SPR_FILE != 0) begin
            $display("Creating sprite from file '%s'.", SPR_FILE);
            $readmemb(SPR_FILE, memory);  // binary text format
        end
    end

    // position within memory array
    logic [$clog2(DEPTH)-1:0] pos;

    // position within sprite
    logic [$clog2(WIDTH)-1:0]  ox;
    logic [$clog2(HEIGHT)-1:0] oy;

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new sprite drawing
        AWAIT_POS,  // await horizontal position
        DRAW,       // draw pixel
        NEXT_LINE   // prepare for next sprite line
    } state, state_next;

    always_ff @(posedge clk) begin
        state <= state_next;  // advance to next state

        if (state == START) begin
            oy <= 0;
            pos <= 0;
        end

        if (state == AWAIT_POS) begin
            ox <= 0;
        end

        if (state == DRAW) begin
            ox <= ox + 1;
            pos <= pos + 1;
        end

        if (state == NEXT_LINE) begin
            oy <= oy + 1;
        end

        if (rst) begin
            state <= IDLE;
            ox <= 0;
            oy <= 0;
            pos <= 0;
        end
    end

    // output current pixel colour when drawing
    always_comb begin
        pix = (state == DRAW) ? memory[pos] : 0;
    end

    // create status signals and correct horizontal position
    logic last_pixel, last_line;
    logic [CORDW-1:0] sprx_cor;
    always_comb begin
        /* verilator lint_off WIDTH */
        last_pixel = (ox == WIDTH-1);
        last_line  = (oy == HEIGHT-1);
        /* verilator lint_on WIDTH */
        sprx_cor = (sprx == 0) ? H_RES_FULL - 1 : sprx - 1;
    end

    // determine next state
    always_comb begin
        case(state)
            IDLE:       state_next = start ? START : IDLE;
            START:      state_next = AWAIT_POS;
            AWAIT_POS:  state_next = (sx == sprx_cor) ? DRAW : AWAIT_POS;
            DRAW:       state_next = !last_pixel ? DRAW : (!last_line ? NEXT_LINE : IDLE);
            NEXT_LINE:  state_next = AWAIT_POS;
            default:    state_next = IDLE;
        endcase
    end
endmodule