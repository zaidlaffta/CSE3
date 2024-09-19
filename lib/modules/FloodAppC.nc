configuration FloodAppC {
    uses interface Boot;
    uses interface AMSend;
    uses interface Receive;
    uses interface Timer<TMilli>;
}

implementation {
    components MainC, ActiveMessageC, TimerMilliC, FloodC;

    FloodC.Boot -> MainC.Boot;
    FloodC.AMSend -> ActiveMessageC.AMSend[AM_FLOOD_TYPE];  // AM Type for Flood
    FloodC.Receive -> ActiveMessageC.Receive[AM_FLOOD_TYPE];
    FloodC.Timer -> TimerMilliC;
}
