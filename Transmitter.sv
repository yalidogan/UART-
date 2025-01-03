`timescale 1ns / 1ps



module Transmitter
#( 
parameter BAUD = 9600, 
parameter CLK_FREQ = 100_000_000, 
parameter StopBits = 2, 
parameter DataWidth = 8

)


(
input logic clk,
input logic [DataWidth - 1:0] data_in, 
input wire [DataWidth - 1:0] leds,
input logic tx_start, //BTNC
input logic tx_load, //BTND
input logic transmitAll, 
output logic tx
);




localparam int bit_timer_limit = CLK_FREQ / (BAUD); 
localparam int Stop_Bit_Limit = StopBits * bit_timer_limit; 

typedef enum logic [1:0]{
    S_IDLE, S_START, S_DATA, S_STOP} states; 
    
    states state = S_IDLE;    
    
integer bittimer; 
integer bitcounter; 
logic [DataWidth - 1 :0] tx_buf ; 
logic [31: 0] tx_fifo_buf = 0; //The fifo buffer for the transmitter 
logic [DataWidth - 1 :0] shreg2 ; 
//logic [19 : 0] DBCounter; 
//logic DBButton; //TXSTART
//logic [19 : 0] DBCounter1; 
//logic DBButton1; //TXLOAD
 
//FIFO Buffer takes the loaded data in and LEFTSHIFTs them as new data comes 
//Transmit the oldest (the data on the MSB) 
//Unless 4 loads are made to the buffer, the output will be 0 

    
assign leds = shreg2;
 

always_ff @(posedge clk) begin


case(state) 

S_IDLE : begin 
tx <= 1; 
bitcounter <= 0; 

    if(tx_load) begin
     tx_fifo_buf <= {tx_fifo_buf[23:0], data_in};
     //The data will be loaded into tx_buf 
    //Load the data onto the fifo and shift it 
    
    //Shift the fifo onto the left discarding the MSByte 
    //Load the data_in here as the loads come in 
    shreg2 <= data_in;
    
    end
    
    if(tx_start) begin 
    state <= S_START; 
    //tx_fifo_buf <= {tx_fifo_buf[23 : 0], tx_buf[7:0]};
   //tx <= 0; 
    end

end //END OF IDLE

S_START : begin 

tx <= 0; 
if(bittimer == bit_timer_limit - 1) begin 
    state <= S_DATA; 
    bittimer <= 0; 
    
    /*
    tx <= tx_buf[0]; 
    
    tx_buf[DataWidth - 1] <= tx_buf[0];
    tx_buf[DataWidth - 2:0]<= tx_buf[DataWidth - 1 : 1];
    */
    
    tx <= tx_fifo_buf[0];
    tx_fifo_buf[7] <= tx_fifo_buf[0];
    tx_fifo_buf[6:0] <= tx_fifo_buf[7:1];
    
end 

else begin 
bittimer <= bittimer + 1; 
end 
end  //END OF START

S_DATA : begin 
    if(bitcounter == DataWidth - 1)begin //all the data has been transferred 
    
        if(bittimer == bit_timer_limit - 1)begin  
        
        bitcounter <= 0; 
        state <= S_STOP; //change state when all the data has been transferred 
        tx <= 1; 
        bittimer <= 0; 

        end
        
        else begin 
        bittimer <= bittimer + 1; 
        end
    
    end
    else begin 
         if(transmitAll)begin 
            if(bittimer == 4*bit_timer_limit - 1) begin 

                     tx <= tx_fifo_buf[0];
                     tx_fifo_buf[7] <= tx_fifo_buf[0];
                     tx_fifo_buf[6:0] <= tx_fifo_buf[7:1];
                 
         bittimer <= 0; 
         bitcounter <= bitcounter + 1; 
         
         end 
         
         else begin
          bittimer <= bittimer + 1; 
         end 
         end 
         if(bittimer == bit_timer_limit - 1) begin 
         /*
                 tx <= tx_buf[0]; 
                 tx_buf[DataWidth - 1] <= tx_buf[0];
                 tx_buf[DataWidth - 2:0]<= tx_buf[DataWidth - 1 :1];
                 */
                 
                     tx <= tx_fifo_buf[0];
                     tx_fifo_buf[7] <= tx_fifo_buf[0];
                     tx_fifo_buf[6:0] <= tx_fifo_buf[7:1];
                 
         bittimer <= 0; 
         bitcounter <= bitcounter + 1; 
         
         end 
         else begin
          bittimer <= bittimer + 1; 
         end 
    end 


end //END OF DATA

S_STOP : begin 

    if(bittimer == Stop_Bit_Limit - 1) begin 
        state <= S_IDLE; 
       // tx_done <= 1; 
        bittimer <= 0; 
        
    end 
    
    else begin
    bittimer <= bittimer + 1;  
    end 
    
end //END OF STOP 
default : state <= S_IDLE;
endcase 
end 

//assign tx_buf_ssd = tx_fifo_buf; 

endmodule