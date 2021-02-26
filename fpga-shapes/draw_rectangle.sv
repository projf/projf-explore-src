// Project F: FPGA Shapes - Draw Rectangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_rectangle #(parameter CORDW=10) (  // FB coord width in bits
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start rectangle drawing
    input  wire logic oe,              // output enable
    input  wire logic [CORDW-1:0] x0,  // vertex 0 - horizontal position
    input  wire logic [CORDW-1:0] y0,  // vertex 0 - vertical position
    input  wire logic [CORDW-1:0] x1,  // vertex 2 - horizontal position
    input  wire logic [CORDW-1:0] y1,  // vertex 2 - vertical position
    output      logic [CORDW-1:0] x,   // horizontal drawing position
    output      logic [CORDW-1:0] y,   // vertical drawing position
    output      logic drawing,         // rectangle is drawing
    output      logic done             // rectangle complete (high for one tick)
    );

    enum {IDLE, INIT, DRAW} state;

    localparam CNT_LINE = 4;  // rectangle has four lines
    logic [$clog2(CNT_LINE)-1:0] line_id;  // current line
    logic line_start;  // start drawing line
    logic line_done;   // finished drawing current line?

    // line coordinates
    logic [CORDW-1:0] lx0, ly0;  // current line start position
    logic [CORDW-1:0] lx1, ly1;  // current line end position

    always @(posedge clk) begin
        line_start <= 0;
        case (state)
            INIT: begin  // register coordinates
                if (line_id == 2'd0) begin  // (x0,y0) -> (x1,y0)
                    lx0 <= x0; ly0 <= y0;
                    lx1 <= x1; ly1 <= y0;
                end else if (line_id == 2'd1) begin  // (x1,y0) -> (x1,y1)
                    lx0 <= x1; ly0 <= y0;
                    lx1 <= x1; ly1 <= y1;
                end else if (line_id == 2'd2) begin  // (x1,y1) -> (x0,y1)
                    lx0 <= x1; ly0 <= y1;
                    lx1 <= x0; ly1 <= y1;
                end else begin  // (x0,y1) -> (x0,y0)
                    lx0 <= x0; ly0 <= y1;
                    lx1 <= x0; ly1 <= y0;
                end
                state <= DRAW;
                line_start <= 1;
            end
            DRAW: begin
                if (line_done) begin
                    /* verilator lint_off WIDTH */
                    if (line_id == CNT_LINE-1) begin
                    /* verilator lint_on WIDTH */
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        line_id <= line_id + 1;
                        state <= INIT;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    line_id <= 0;
                    state <= INIT;
                end
            end
        endcase

        if (rst) begin
            line_id <= 0;
            line_start <= 0;
            done <= 0;
            state <= IDLE;
        end
    end

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk,
        .rst,
        .start(line_start),
        .oe,
        .x0(lx0),
        .y0(ly0),
        .x1(lx1),
        .y1(ly1),
        .x,
        .y,
        .drawing,
        .done(line_done)
    );
endmodule
