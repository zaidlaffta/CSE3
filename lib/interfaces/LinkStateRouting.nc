#include "../../includes/packet.h"


interface LinkStateRouting{
	command void start();
	command void print();
	command uint16_t getNextHop(uint16_t dest);
    command void handleLS(pack* myMsg); // New command declaration for handleLS

}