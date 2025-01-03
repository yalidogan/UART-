`timescale 1ns / 1ps



module Receiver
#( 
parameter BAUD = 9600, 
parameter CLK_FREQ = 100_000_000, 
parameter DataWidth = 8
)

(
input logic clk, 
input logic rx_i,  
output [7:0] rx_out
    );
    
    
    localparam int bit_timer_limit = CLK_FREQ /BAUD;  
    
    typedef enum logic [1:0]{
    S_IDLE, S_START, S_DATA, S_STOP} states; 
    
     states state = S_IDLE;  
     
     integer bittimer = 0; 
     integer bitcounter = 0; 
     logic [7: 0] rx_buf = 0; //Leave this be 
     logic [31: 0] rx_fifo_buf = 0; 
     //Shift it 4 times to the left and take the transmission 
     logic rx_done;
     
     always_ff @(posedge clk) begin  
case(state) 
S_IDLE : begin 
bittimer <= 0; 
rx_done <= 0; 

if(rx_i == 0) begin //TODO
state <= S_START;
end 
end //END OF SIDLE

S_START : begin 
if((bittimer == bit_timer_limit / 2 - 1) ) begin 
       if(rx_i == 0) begin
       state <= S_DATA;
       end else begin
       state <= S_IDLE; 
       end 
    bittimer <= 0; 
end 
else begin 
bittimer <= bittimer + 1; 
end 
end //end of start

S_DATA : begin 
if(bittimer == bit_timer_limit - 1) begin 
     if(bitcounter == DataWidth - 1) begin //The last transmisison occurred 
        state <= S_STOP; //Now rx_buf has the whole transmission 
        //rx_fifo_buf = {rx_fifo_buf[23 : 0], rx_buf[7:0]};
        bitcounter <= 0; 
    
        end
    else begin 
        bitcounter <= bitcounter + 1; 
    end
    
    //rx_buf <= {rx_i,rx_buf[DataWidth - 1 : 1]}; 
    rx_fifo_buf <= {rx_i, rx_fifo_buf[31 : 1]};
    //tx_fifo_buf <= {tx_fifo_buf[23:0], data_in};
    //rx_fifo_buf <= {rx_fifo_buf[30:0], rx_i};

    
    bittimer <= 0; 
end
    else begin 
    bittimer <= bittimer + 1; 
    end 
end //end of data

S_STOP : begin 

    if ( bittimer == bit_timer_limit - 1) begin 
        state <= S_IDLE;
        bittimer <= 0; 
        rx_done <= 1; 
        //rx_buf <= rx_fifo_buf[31 : 24];
        
        //Take the tranmission from the receiver buffer and 
        //Add it to the fifo, shifting it by 4 bits along the way 
    end

    else begin 
        bittimer <= bittimer + 1; 
    end 


end //end of stop 
endcase 
end
assign rx_out = rx_fifo_buf[7:0]; 
//assign rx_out = rx_buf; 
//assign rx_buf_ssd = rx_fifo_buf;
endmodule
