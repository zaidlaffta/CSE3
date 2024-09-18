configuration Flood {  
    provides interface StdControl;  
    uses interface Packet;  
    uses interface AMSend;  
    uses interface Receive;  
    uses interface Timer<TMilli> as FloodTimer;  
}  
  
implementation {  
    components FloodC;  
    FloodC.Packet -> ActiveMessageC.Packet;  
    FloodC.AMSend -> ActiveMessageC.AMSend[AM_BROADCAST_ADDR];  
    FloodC.Receive -> ActiveMessageC.Receive[AM_BROADCAST_ADDR];  
    FloodC.FloodTimer -> TimerMilliC;  
}  
