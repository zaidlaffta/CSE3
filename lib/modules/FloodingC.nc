//CSE160
//Project 1
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"

configuration FloodingC {
	// The FloodingC configuration provides the Flooding interface to other modules.
	provides interface Flooding;
}

implementation {
	// The FloodingC component 
	components FloodingP;
	Flooding = FloodingP;
	// Instantiate a HashMap component to store previously received packets to avoid redundant flooding.
	components new HashmapC(uint32_t, 25);
	//Instantiate a Map component (with key as uint32_t) to track received packets.
	components new MapC(uint32_t, 20);

	//Wiring for Flooding
    //used as a packet identifyer - mentioned in the Lab by Jothi
	FloodingP.PreviousPackets -> HashmapC;
	// Instantiate the SimpleSendC component for sending messages using the Active Message (AM) protocol.
	components new SimpleSendC(AM_PACK);
	FloodingP.simpleSend -> SimpleSendC;
}
