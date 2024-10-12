// Project 1
// CSE 160
// LinkStateRouting.nc
// Sep/28/2024
// Zaid Laffta
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"

interface LinkStateRouting{
	command void start();
	command void print();
	command uint16_t getNextHop(uint16_t dest);
	command message_t* receive(message_t* myMsg, void* payload, uint8_t len);
}
