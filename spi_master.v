module spi_master(clk,rst,start,MODE,clkdiv,DatatoTransmit,finish,
                  DataReceived,MISO,Sclk,MOSI,SS);
  
  input clk,rst,start;
  input [1:0] clkdiv,MODE;
  input [7:0] DatatoTransmit;
  output reg finish;
  output reg [7:0]DataReceived;
  
  ////4 wires of SPI////
  
  input MISO;
  output reg MOSI,Sclk,SS;
  
  
  
  // Intermediate signals //
  
  wire CPOL,CPHA,Txcomplete;
  wire clkEn; // this activates Sclk
  wire [4:0] next_count;
  reg [4:0] count;
  reg [4:0] halfcycle;
  reg midcycle,sample_En,shift_En;
  reg sample,shift;
  reg bitcount_En;
  reg [1:0] current_state,next_state;
  reg [7:0] MasterReg;
  reg [7:0] bitcount;
  
  //////////////////////////
  
  parameter IDLE  = 2'b11;
  parameter BEGIN = 2'b10;
  parameter LEAD  = 2'b01;
  parameter TRAIL = 2'b00;
  
  // CPOL - Clock polarity
  // CPHA - Clock phase
  // CPOL decides leading/trailing edge should be pos/neg edge
  // if CPOL is low, then clock starts from zero so leading edge is pos edge
  // if CPOL is high,then clock starts from high so leading edge is neg edge
  // CPHA decides at which edge sampling and shift shall occur
  // if CPHA is low, SAMPLING->leading  edge, SHIFTING -> trailing edge
  // if CPHA is high,SAMPLING->trailing edge, SHIFTING -> leading edge
  // mode 0 => CPOL = 0 ,CPHA = 0
  // mode 1 => CPOL = 0 ,CPHA = 1
  // mode 2 => CPOL = 1 ,CPHA = 0
  // mode 3 => CPOL = 1 ,CPHA = 1
  
  
  assign CPOL = (MODE==2) || (MODE==3);
  assign CPHA = (MODE==1) || (MODE==3);
  
  assign next_count[4:0] = count[4:0] + 1'b1;
  assign clkEn = (next_count == halfcycle);
  

  
  // if clkdiv is 4(00), then halfcycle becomes 0001 see next always block
  // so clkEn = (next_count == {4'b00010})
  // that is Clken becomes high when count reaches half of clkdiv input
    // clkdiv 00 -> Freq Division by 4
  // clkdiv 00 -> Freq Division by 4
  // clkdiv 00 -> Freq Division by 4
  // clkdiv 00 -> Freq Division by 4
  
  ////// clock divider  /////
  
  always @(clkdiv)
    case(clkdiv)
      2'b00: halfcycle = 5'b00010;      // clkdiv 00 -> Freq Division by 4  
      2'b01: halfcycle = 5'b00100;      // clkdiv 01 -> Freq Division by 8      
      2'b10: halfcycle = 5'b01000;      // clkdiv 10 -> Freq Division by 16
      2'b11: halfcycle = 5'b10000;      // clkdiv 11 -> Freq Division by 32
      default:;
    endcase
  
  
  //// fsm for next state logic ////
  
  always @(current_state,start,midcycle,Txcomplete)
    begin
      case(current_state)
        IDLE : // only if start is HIGH,next state-> BEGIN
               begin
               if(!start)
                next_state <= IDLE;
               else
                next_state <= BEGIN;
               end
        
        BEGIN : next_state <= LEAD;
        
        LEAD  : // if midcycle is HIGH, then edge transition occurs
                begin   
                  if(midcycle)
                   next_state <= TRAIL;
                  else
                   next_state <= LEAD;
                end
        
        TRAIL : // If Tx is complete , go to IDLE
                // else  check for midcycle
                // if midcycle is HIGH,then edge transition occurs    
                begin
                  case({Txcomplete,midcycle})
                    2'b00:next_state <= TRAIL;
                    2'b01:next_state <= LEAD;
                    2'b10:next_state <= IDLE;
                    2'b00:next_state <= IDLE; 
                    default:next_state <= IDLE;
                  endcase
                end
        
        default : ;
      endcase
    end
  //////////////////////////////////////////////////////////////////////////
  
        
  ///////////// FSM to generate Sclk ///////////////////////////////////////
  
  // CPOL - Clock polarity
  // CPHA - Clock phase
  // CPOL decides leading/trailing edge should be pos/neg edge
  // if CPOL is low, then clock starts from zero so leading edge is pos edge
  // if CPOL is high,then clock starts from high so leading edge is neg edge
  // CPHA decides at which edge sampling and shift shall occur
  // if CPHA is low, SAMPLING->leading  edge, SHIFTING -> trailing edge
  // if CPHA is high,SAMPLING->trailing edge, SHIFTING -> leading edge
  // mode 0 => CPOL = 0 ,CPHA = 0
  // mode 1 => CPOL = 0 ,CPHA = 1
  // mode 2 => CPOL = 1 ,CPHA = 0
  // mode 3 => CPOL = 1 ,CPHA = 1    
        
        
  
   always@(current_state,Txcomplete,CPOL)
     begin
       case(current_state)
         IDLE  : //in idle state  always Sclk follows Clock polarity (CPOL)  
                 begin
                   SS     <= 1;
                   Sclk   <= CPOL;
                   finish <= 1;
                 end
         
         BEGIN : //in begin state, we start communication making SS LOW
                 begin
                   SS     <= 0;
                   Sclk   <= CPOL;
                   finish <= 0; 
                 end 
         
         LEAD  :  // LEAD = 01 ,so current state[0] = 1
                  //for mode 0,1 leading edge for Sclk is pos edge so make Sclk HIGH 
                  //for mode 2,3 leading edge for Sclk is neg edge so make Sclk LOW
                  // to choose between them both , use XOR operation
                  // if mode is 2 or 3, CPOL =1 so 1^1 = 0
                  // if mode is 0 or 1, CPOL =0 so 0^1 = 1
           
                  begin
                   SS    <= 0;
                   Sclk  <= CPOL ^ current_state[0];
                   finish <= 0;
                  end
         
         TRAIL :  // LEAD = 00 ,so current state[0] = 0
                  //for mode 0,1 trailing edge for Sclk is neg edge so make Sclk LOW 
                  //for mode 2,3 trailing edge for Sclk is pos edge so make Sclk HIGH
                  // to choose between them both , use XOR operation
                  // if mode is 2 or 3, CPOL =1 so 1^0 = 1
                  // if mode is 0 or 1, CPOL =0 so 0^0 = 0
                  // if data transfer is done , make finish HIGH
                  // if Txcomplete is high , make finish high
                   begin
                   SS    <= 0;
                   Sclk  <= CPOL ^ current_state[0];
                     if(Txcomplete)
                       finish <= 1;
                     else
                       finish <= 0;
        
                   end
          default:;
       endcase
     end
        
 /////////////// logic to generate Sclk //////////////////////
 // high pulse of start triggers state to go idle state
 // when next_count reaches half the count of Clkdiv input, clken becomes high , 
 // so when clken becomes high , sclk needs to be toggles by looking at midcycle signal
        
        always@(posedge clk)
          begin
            if(current_state == IDLE) // only at idle state,we make both midcycle and count LOW
              begin
                  midcycle <= 0;
                  count <= 0;
              end
            else  // at other states, we start counting.
              begin
                case({rst,clkEn})
                  2'b00:begin
                        midcycle <= 0;
                        count <= next_count;
                        end
                  2'b01:begin
                        midcycle <= 1;
                        count <= 0;
                        end 
                  2'b10,2'b11:
                        begin
                        midcycle <= 0;
                        count <= 0;
                        end
                  default: ;
                endcase
              end 
                    
            end
        
 ////////////////////////////////////////////////////////////////////
        
 ///////// Sampling data from MISO line and shifting master data register/////////
        
        
        always@(current_state,next_state,midcycle,sample,shift,CPHA)
          begin
            case(current_state)
              
              IDLE:
                   begin
                     bitcount_En <= 0;
                     shift_En<=0;
                     sample_En <= 0;
                   end
        
             BEGIN:
                   begin
                     bitcount_En <= 0;
                     if ( next_state == LEAD ) 
                       begin
                         if(CPHA==0) 
                           begin
                             shift_En <= 1'b0;
                             sample_En <= 1'b1;                   
                           end 
                         else 
                           begin
                            shift_En <= 1'b1;
                            sample_En <= 1'b0;  
                           end
                        end 
                     else 
                       begin
                         shift_En <= 1'b0;
                         sample_En <= 1'b0;
                      end
                   end
              
             LEAD:
                  begin
                    if(midcycle)
                      begin
                        if(CPHA==0)
                           begin
                             sample_En <= 0;  // when midcycle is high at LEAD state , next edge is trailing
                                            // coz in trailing edge we only shift not sample,so shift is made LOW
                             if(shift == 0)
                               shift_En <= 1'b1;
                             else 
                               shift_En <= 1'b0;
                           end 
                         else
                            begin
                            shift_En <= 1'b0;
                              if ( !sample )
                                 sample <= 1'b1;
                              else
                                 sample_En <= 1'b0;
                            end
                        end
                    else
                        begin
                          shift_En <= 1'b0;
                          sample_En <= 1'b0;
                        end
                   if (next_state == TRAIL)
                       bitcount_En <= 1'b1;
                   else
                      bitcount_En <= 1'b0;
               end
              
              
            TRAIL : 
                   begin
                     bitcount_En <= 1'b0;
                     if(midcycle) 
                       begin
                         if (CPHA == 0) 
                           begin
                           shift_En <= 1'b0;
                             if ( !sample )
                              sample_En <= 1'b1;
                           else
                              sample_En <= 1'b0;
                           end 
                         else 
                           begin
                             sample_En <= 1'b0;
                            if ( !shift )
                               shift_En <= 1'b1;
                             else
                               shift_En <= 1'b0;
                           end
                       end 
                    else 
                      begin
                        sample_En <= 1'b0;
                        shift_En <= 1'b0;
                      end
                  end
                default:;
            endcase
          end
              
  assign Txcomplete = &bitcount; // when all bits are sent, Tx complete becomes High 
              
              
////////////////////////// Updating state machine //////////////////////////////////////////////////

             always@(posedge clk)
                 begin
                   if(rst) 
                     begin
                       current_state <= IDLE;
                       MasterReg <= 0;
                       DataReceived <= 0;
                       bitcount <= 0;
                     end 
                   else 
                     begin
                        current_state <= next_state;
                       if(start) 
                ///// Load DatatoTransmit into MasterReg if Start receives HIGH pulse
                          MasterReg <= DatatoTransmit;
                       else
                          MasterReg <= MasterReg;


                       if(current_state==BEGIN && CPHA==1'b0) 
                ///// MOSI is driven for case where a Data Tx is started and CPHA = 0
                          begin
                            MOSI <= DatatoTransmit[7];
                            MasterReg <= {DatatoTransmit[6:0], 1'b0};
                          end


                       if(shift_En)
         //If shift_En receives HIGH,then begin shifting the register onto MOSI port.
                          begin
                            MasterReg <= {MasterReg[6:0], 1'b0};
                            MOSI <= MasterReg[7];
                          end

                       shift <= shift_En;


                       if(sample_En)
         // If sample_En receives HIGH pulse, read the data from MISO
                         begin
                           DataReceived <= {DataReceived[6:0], MISO};
                         end

                       sample <= sample_En;

                       if(Txcomplete) 
                           begin
                           bitcount <= 0; 
                           end  
                          else if(bitcount_En)
                              bitcount <= {bitcount[6:0], 1'b1};
                       else 
                               bitcount <= bitcount;
                       
                     end
                 end
endmodule
                   
                           
                
                   
                   
                        
                
