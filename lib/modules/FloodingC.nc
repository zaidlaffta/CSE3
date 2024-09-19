#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"

configuration FloodingC {
	// The FloodingC configuration provides the Flooding interface to other modules.
	provides interface Flooding;
}

implementation {
	// The FloodingC component uses the FloodingP module for its implementation.
	components FloodingP;
	Flooding = FloodingP;

	// Instantiate the SimpleSendC component for sending messages using the Active Message (AM) protocol.
	components new SimpleSendC(AM_PACK);
	FloodingP.simpleSend -> SimpleSendC;

	// Instantiate a HashMap component to store previously received packets to avoid redundant flooding.
	components new HashmapC(uint32_t, 20);
    //used as a packet identifyer - mentioned in the Lab by Jothi
	FloodingP.PreviousPackets -> HashmapC;
}
