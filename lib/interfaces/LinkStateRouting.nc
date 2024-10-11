#include "../../includes/packet.h"
#include "../../includes/listInfo.h"

interface LinkStateRouting{
	command void start();
	command void print();
	command uint16_t getNextHop(uint16_t dest);
}