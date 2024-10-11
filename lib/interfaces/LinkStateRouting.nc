#include "../../includes/packet.h"


interface LinkStateRouting{
	command void start();
	command void print();
	command uint16_t getNextHop(uint16_t dest);
}