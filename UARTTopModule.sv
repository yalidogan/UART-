`timescale 1ns / 1ps
module uart_TX#(
    parameter DATA_SIZE = 8,
    parameter STOP_BIT_COUNT = 2,
    parameter BAUD_RATE_COUNTER = 10415 // 9600 baud
)(
    input wire clk,
    input wire reset,
    input wire [DATA_SIZE-1:0] data_in,
    input wire loadDataBtn,
    input wire transferStartBtn,
    output reg tx,
    output wire [DATA_SIZE-1:0] tx_led
);


reg [1:0] state = 0;
localparam idle = 2'b00;
localparam start = 2'b01;
localparam data = 2'b10;
localparam stop = 2'b11;

reg[DATA_SIZE-1:0] TXBUF = 0;
reg[3:0] data_index = 0;
reg[$clog2(BAUD_RATE_COUNTER):0] counter = 0;
reg[$clog2(STOP_BIT_COUNT):0] stop_bit_counter = 0;
reg [19:0] debounce_counter_load = 0;
reg debounced_loadDataBtn;
reg [19:0] debounce_counter_trans = 0;
reg debounced_transferStartBtn;
assign tx_led = TXBUF;

always @(posedge clk) begin

    //Button Debounce
    if (loadDataBtn != debounced_loadDataBtn) begin
        debounce_counter_load <= debounce_counter_load + 1;
        if (debounce_counter_load == 20'd1000000) begin
            debounced_loadDataBtn <= loadDataBtn;
            debounce_counter_load <= 0;
        end
    end else begin
        debounce_counter_load <= 0;
    end
    if (transferStartBtn != debounced_transferStartBtn) begin
        debounce_counter_trans <= debounce_counter_trans + 1;
        if (debounce_counter_trans == 20'd1000000) begin
            debounced_transferStartBtn <= transferStartBtn;
            debounce_counter_trans <= 0;
        end
    end else begin
        debounce_counter_trans <= 0;
    end
    //Actual State and Reset Logic
    if(reset) begin
    state <= idle;
    tx <= 1'b1;
    counter <= 0;
    stop_bit_counter <= 0;
    data_index <= 0;
    TXBUF <= 0;
    end
    else begin
        case(state)
            idle: begin
                tx <= 1'b1;
                if(debounced_loadDataBtn) begin
                    TXBUF <= data_in;
                end
                if(debounced_transferStartBtn) begin
                    state <= start;
                    counter <= 0;
                end
            end
            start:begin
                tx <= 1'b0;//start bit
                if(counter < BAUD_RATE_COUNTER - 1) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    state <= data;
                    data_index <= 0;
                end
            end
            data:begin
                tx <= TXBUF[data_index];
                if(counter < BAUD_RATE_COUNTER - 1) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    if(data_index < DATA_SIZE) begin
                        data_index <= data_index + 1;
                    end else begin
                        state <= stop;
                        stop_bit_counter <= 0;
                    end
                end
            end
            stop:begin
                tx<= 1'b1; //stop bits value = 1;
                if(counter < BAUD_RATE_COUNTER - 1) begin
                    counter <= counter + 1;
                end else begin
                    if(stop_bit_counter < STOP_BIT_COUNT - 1 ) begin 
                        stop_bit_counter <= stop_bit_counter + 1;
                        counter <= 0;
                    end else begin
                        state <= idle;
                    end
                end
            end
            default : state <= idle;
        endcase
    end
end
endmodule







`timescale 1ns / 1ps
module uart_RX#(
    parameter DATA_SIZE = 8,
    parameter STOP_BIT_COUNT = 2,
    parameter BAUD_RATE_COUNTER = 10415 // 9600 baud
)(
    input wire clk,
    input wire reset,
    input wire txInput,
    output wire [DATA_SIZE-1:0] outputLed
);

reg[1:0] state = 0;
localparam idle = 2'b00;
localparam start = 2'b01;
localparam read = 2'b10;
localparam stop = 2'b11;

reg[DATA_SIZE-1:0] RXBUF;
reg[3:0] read_index;
reg[$clog2(BAUD_RATE_COUNTER):0] counter = 0;
reg[$clog2(STOP_BIT_COUNT):0] stop_bit_counter = 0;

assign outputLed = RXBUF;

always @(posedge clk) begin
    if(reset)begin
        state <= idle;
        RXBUF <= 0;
        read_index <= 0;
        counter <= 0;
        stop_bit_counter <= 0;
    end else begin
        case(state)
            idle: begin
                if(txInput == 0) begin
                    counter <= 0;
                    state <= start;
                end
                read_index <= 0;
            end
            start: begin
                if(counter > (BAUD_RATE_COUNTER/2)) begin
                    if(txInput == 0) begin
                        state <= read;
                    end else begin
                        state <= idle;
                    end
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end
            read: begin
                if(counter < BAUD_RATE_COUNTER) begin
                    counter <= counter + 1;
                end else begin
                    if(read_index < DATA_SIZE) begin
                        RXBUF[read_index] <= txInput;
                        read_index <= read_index + 1;
                    end else begin
                        state <= stop;
                        stop_bit_counter <= 0;
                    end
                    counter <= 0;
                end
            end
            stop: begin
                if(counter < BAUD_RATE_COUNTER) begin
                    counter <= counter + 1;
                end else begin
                    if(stop_bit_counter < STOP_BIT_COUNT - 1 ) begin 
                        stop_bit_counter <= stop_bit_counter + 1;
                        counter <= 0;
                    end else begin
                        state <= idle;
                    end
                end
            end
            default : state <= idle;
        endcase
    end
end





endmodule


`timescale 1ns / 1ps
module uart_Top
#(
    parameter DATA_SIZE = 8,
    parameter STOP_BIT_COUNT = 2,
    parameter BAUD_RATE_COUNTER = 10415
)
(
    input wire [15:0] sw,
    output wire[15:0] LED,
    input wire btnD,btnC,
    input wire clk,
    inout wire [3:4] JA
);  
    
    uart_TX#(
        .DATA_SIZE(DATA_SIZE),
        .STOP_BIT_COUNT(STOP_BIT_COUNT),
        .BAUD_RATE_COUNTER(BAUD_RATE_COUNTER)
    ) transmit (
        .clk(clk),
        .reset(sw[15]),
        .data_in(sw[7:0]),
        .loadDataBtn(btnD),
        .transferStartBtn(btnC),
        .tx(JA[3]),
        .tx_led(LED[7:0])
    );
    
    uart_RX#(
        .DATA_SIZE(DATA_SIZE),
        .BAUD_RATE_COUNTER(BAUD_RATE_COUNTER)
    ) recieve (
        .clk(clk),
        .reset(sw[15]),
        .txInput(JA[4]),
        .outputLed(LED[15:8])
    );

endmodule




