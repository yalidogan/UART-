`timescale 1ns / 1ps



module UART_TopModule


(
input logic clk, 
input logic [7:0] sw, 
input logic btnC, 
input logic btnD, 
input logic btnR, 
input logic btnL, 
//input logic sw15,
inout logic [1:0] JA,
output logic [15 : 0] LED
);

  
  Transmitter transmitter(
  .clk(clk),
  .data_in(sw[7:0]),
  .leds(LED[7:0]),
  .tx_start(btnC),
  .tx_load(btnD),
  .tx(JA[0]) 
  //.transmitAll(sw15)
  );
   
    
 Receiver receiver(
    .clk(clk), 
    .rx_i(JA[1])
    );
    

  
endmodule
