`timescale 1ns / 1ps

(* KEEP_HIERARCHY = "TRUE" *)
module puf_uart_system #(
    parameter CLK_FREQ = 100000000, // 100MHz (Standard for Basys3/Arty boards)
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire rst_n, // Active-LOW reset from board
    input  wire rx,    // Serial input from PC
    output wire tx     // Serial output to PC
);

    wire rx_done;
    wire [7:0] rx_data;

    // FIX 1: Pass ~rst_n to UART modules because they expect Active-HIGH resets
    UART_Rx #(
        .clk_freq(CLK_FREQ),
        .baudrate(BAUD_RATE)
    ) uart_receiver (
        .clk(clk),
        .rst(~rst_n), 
        .data_in(rx),
        .done(rx_done),
        .data_out(rx_data)
    );

    reg  [7:0] tx_data;
    reg  tx_avail;
    wire tx_done;
    wire tx_busy;

    UART_tx #(
        .clk_freq(CLK_FREQ),
        .baudrate(BAUD_RATE)
    ) uart_transmitter (
        .clk(clk),
        .reset(~rst_n), 
        .data_in(tx_data),
        .avail(tx_avail),
        .tx(tx),
        .done(tx_done),
        .busy(tx_busy)
    );

    reg  puf_pulse;
    reg  [127:0] puf_challenge;
    
    wire [(21*3)-1:0] puf_response; 
    wire [20:0] puf_valid;          

    cryptographic_puf_top #(
        .NUM_BLOCKS(21) 
    ) puf_array (
        .challenge_pulse(puf_pulse),
        .master_challenge({21{puf_challenge}}), 
        .aggregated_response(puf_response),
        .aggregated_valid(puf_valid)
    );

    localparam [1:0] STATE_RX    = 2'd0,
                     STATE_PULSE = 2'd1,
                     STATE_WAIT  = 2'd2,
                     STATE_TX    = 2'd3;

    reg [1:0]   state;
    reg [4:0]   byte_count;       
    reg [9:0]   delay_cnt;        
    reg [63:0]  tx_shift_reg;     

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_RX;
            byte_count    <= 5'd0;
            delay_cnt     <= 10'd0;
            puf_pulse     <= 1'b0;
            tx_avail      <= 1'b0;
            puf_challenge <= 128'd0;
            tx_data       <= 8'd0;
            tx_shift_reg  <= 64'd0; 
        end else begin
            tx_avail <= 1'b0; 

            case (state)
                
                STATE_RX: begin
                    if (rx_done) begin
                        puf_challenge <= {puf_challenge[119:0], rx_data}; 
                        
                        if (byte_count == 5'd15) begin
                            byte_count <= 5'd0;
                            state      <= STATE_PULSE;
                        end else begin
                            byte_count <= byte_count + 5'd1;
                        end
                    end
                end

                STATE_PULSE: begin
                    puf_pulse <= 1'b1; 
                    delay_cnt <= delay_cnt + 10'd1;
                    
                    if (delay_cnt == 10'd1000) begin 
                        // FIX 2: Do NOT drop puf_pulse here. Keep it high so the 
                        // XNOR filter doesn't reset before we latch the data.
                        delay_cnt <= 10'd0;
                        state     <= STATE_WAIT;
                    end
                end

                STATE_WAIT: begin
                    delay_cnt <= delay_cnt + 10'd1;
                    
                    if (delay_cnt == 10'd10) begin
                        tx_shift_reg <= {1'b0, puf_response};
                        puf_pulse    <= 1'b0; // FIX 2: Now it's safe to turn off the PUF
                        byte_count   <= 5'd0;
                        delay_cnt    <= 10'd0;
                        state        <= STATE_TX;
                    end
                end

                STATE_TX: begin
                        // 1. Always check if a transmission just finished FIRST
                        if (tx_done) begin
                            tx_shift_reg <= {tx_shift_reg[55:0], 8'b0}; 
                            
                            if (byte_count == 5'd7) begin
                                byte_count <= 5'd0;
                                state      <= STATE_RX; 
                            end else begin
                                byte_count <= byte_count + 5'd1;
                            end
                        end
                        // 2. If we aren't finishing a byte, see if we are ready to start a new one
                        else if (!tx_busy && !tx_avail) begin
                            tx_data  <= tx_shift_reg[63:56]; 
                            tx_avail <= 1'b1;                
                        end 
                    end 
        
                default: begin
                    state <= STATE_RX;
                end
            endcase
        end
    end
endmodule