//Author: UCM ANDES Lab
//$Author: abeltran2 $
//$LastChangedDate: 2014-06-16 13:16:24 -0700 (Mon, 16 Jun 2014) $

#ifndef PROTOCOL_H
#define PROTOCOL_H

//PROTOCOLS
enum{
	PROTOCOL_PING = 0,
	PROTOCOL_PINGREPLY = 1,
	PROTOCOL_LINKEDLIST = 2,
	PROTOCOL_NAME = 3,
	PROTOCOL_TCP= 4,
	PROTOCOL_DV = 5,
    PROTOCOL_CMD = 99,
	PROTOCOL_TO_ROOT = 6,
	PROTOCOL_FROM_ROOT = 7,
	PROTOCOLE_BEACON_UP = 8,
	PROTOCOL_BEACON_DOWN = 9,
	PROTOCOL_RNP_UP = 10,
	PROTOCOL__RNP_DOWN = 11
};



#endif /* PROTOCOL_H */
