`timescale 1ns / 1ps



module ButtonDebouncer
#(parameter
integer clk_freq = 100_000_000, 
integer debounce_time = 1000, 
logic initial_value = 0)

(
input logic clk, 
input logic signal_in, 
output logic signal_out 
);
    
    
 localparam integer timer_limit = clk_freq / debounce_time; 
 logic [31 : 0] timer; 
 logic timer_enable = 0; 
 logic timer_tick = 0;
 
 typedef enum logic [2:0] {
 S_INIT, S_ZERO, S_ZEROTOONE, S_ONE, S_ONETOZERO} states;
 
 states state = S_INIT;
 
 always_ff @(posedge clk) begin 
 case(state) 
 S_INIT : begin
 
 if(initial_value == 0) begin 
 state <= S_ZERO; 
 end  
 else begin 
 state <= S_ONE;
 end 
 end 
 
 S_ZERO: begin
 signal_out <= 0; 
 
 if(signal_in == 1) begin 
 state <= S_ZEROTOONE; 
 end 
 end 
 
 S_ZEROTOONE : begin 
 
 signal_out <= 0; 
 timer_enable <= 1; 
 
 if(timer_tick == 1) begin 
 state <= S_ONE; 
 timer_enable <= 0; 
 end
 
 if(timer_tick == 0) begin 
 state <= S_ZERO; 
 timer_enable <= 0; 
 end 
 
 
 
 end 
 
 S_ONE : begin 
 signal_out <= 1; 
 
 if(signal_in == 0)begin 
 state <= S_ONETOZERO;
 end 
 
 end 
 
 S_ONETOZERO : begin 
 
 signal_out <= 1; 
 timer_enable <= 1; 
 
 if(timer_enable == 1) begin 
 state <= S_ZERO; 
 timer_enable <= 0; 
 end
 
 if(signal_in == 1) begin 
 state <= S_ONE; 
 timer_enable <= 0;
 end 
 end
 
 endcase 
 end 
 
 always_ff @(posedge clk) begin 
    if(timer_enable == 1) begin 
        if(timer == timer_limit - 1) begin 
            timer_tick <= 1; 
            timer <= 0; 
        end 
        
        else begin 
            timer_tick <= 0; 
            timer <= timer + 1; 
        end 
        
        
    end 
    
    else begin 
    timer <= 0; 
    timer_tick <= 0;
    end 

 end 

endmodule
